class Enterprise::Billing::HandleStripeEventService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze
  CAPTAIN_CLOUD_PLAN_LIMITS = 'CAPTAIN_CLOUD_PLAN_LIMITS'.freeze
  PAST_DUE_GRACE_PERIOD = 7.days

  def perform(event:)
    @event = event

    ProcessedWebhookEvent.transaction do
      if ProcessedWebhookEvent.exists?(stripe_event_id: @event.id)
        Rails.logger.warn("Stripe event #{@event.id} already processed. Skipping.")
        return true
      end

      ProcessedWebhookEvent.create!(
        stripe_event_id: @event.id,
        event_type: @event.type,
        processed_at: Time.current
      )

      case @event.type
      when 'customer.subscription.created', 'customer.subscription.updated'
        process_subscription_updated
      when 'customer.subscription.deleted'
        process_subscription_deleted
      when 'checkout.session.completed'
        process_checkout_session_completed
      when 'invoice.payment_succeeded'
        record_payment_transaction(status: 'succeeded')
        record_billing_activity_from_invoice(status: 'success')
        process_invoice_payment_succeeded
      when 'invoice.payment_failed'
        record_payment_transaction(status: 'failed')
        record_billing_activity_from_invoice(status: 'failed')
      when 'payment_intent.payment_failed'
        record_payment_intent_failed_billing_activity
      else
        Rails.logger.debug { "Unhandled event type: #{@event.type}" }
      end
    end
  end

  private

  def process_checkout_session_completed
    session = @event.data.object
    return unless session.metadata['source'] == 'captain_topup'

    payer_account = Account.find_by(id: session.metadata['account_id'])
    return if payer_account.blank?

    credits = session.metadata['credits'].to_i
    amount = session.metadata['amount'].to_f
    currency = session.metadata['currency'].presence || 'usd'
    return if credits <= 0

    Enterprise::Billing::TopupFulfillmentService.new(account: payer_account).fulfill(
      credits: credits,
      amount_cents: (amount * 100).to_i,
      currency: currency,
      stripe_session_id: session.id
    )

    record_topup_payment_transaction(payer_account, session, credits, amount, currency)
  end

  def record_topup_payment_transaction(payer_account, session, credits, amount, currency)
    invoice = retrieve_checkout_invoice(session)
    description = "Captain AI Credits - #{credits} credits"

    if invoice.present?
      Enterprise::Billing::RecordPaymentTransactionService.new(
        account: payer_account,
        invoice: invoice,
        status: 'succeeded'
      ).perform
      # Prefer the Captain-specific label over Stripe's generic line description.
      PaymentTransaction.find_by(stripe_invoice_id: invoice.id)&.update!(
        description: description,
        billing_reason: 'captain_topup'
      )
      return
    end

    PaymentTransaction.find_or_initialize_by(
      stripe_invoice_id: session['payment_intent'].presence || session.id
    ).update!(
      account: payer_account,
      stripe_customer_id: session.customer,
      amount: amount,
      currency: currency,
      status: 'succeeded',
      description: description,
      billing_reason: 'captain_topup',
      paid_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error("Failed to record topup payment transaction for session #{session.id}: #{e.message}")
  end

  def retrieve_checkout_invoice(session)
    invoice_id = session['invoice'].presence
    return Stripe::Invoice.retrieve(invoice_id) if invoice_id.present?

    # invoice_creation can attach the invoice slightly after session.completed -
    # re-fetch the session once so Payment History gets the hosted invoice link.
    refreshed = Stripe::Checkout::Session.retrieve(session.id)
    invoice_id = refreshed['invoice'].presence
    Stripe::Invoice.retrieve(invoice_id) if invoice_id.present?
  rescue Stripe::StripeError => e
    Rails.logger.warn("[topup] could not load invoice for session #{session.id}: #{e.message}")
    nil
  end

  def process_subscription_updated
    if marketplace_subscription?
      process_marketplace_subscription_updated
    else
      process_platform_subscription_updated
    end
  end

  def process_marketplace_subscription_updated
    client_account_id = subscription.metadata['client_account_id']
    client_account = Account.find_by(id: client_account_id)
    return if client_account.blank?

    plan_price_id = subscription.metadata['marketplace_plan_price_id']
    plan_price = MarketplacePlanPrice.find_by(id: plan_price_id)
    return if plan_price.blank?

    sub_record = Subscription.find_or_initialize_by(account: client_account)
    sub_record.update!(
      payment_provider: 'stripe',
      stripe_customer_id: subscription.customer,
      stripe_subscription_id: subscription.id,
      status: subscription.status,
      relationship_type: 'marketplace',
      connected_account_id: subscription.metadata['connected_account_id'],
      application_fee_amount: plan_price.platform_fee_amount,
      stripe_price_id: subscription['plan']['id'],
      stripe_product_id: subscription['plan']['product'],
      plan_name: 'Workspace Subscription',
      subscribed_quantity: subscription['quantity'],
      current_period_start: Time.zone.at(subscription_period_start),
      current_period_end: Time.zone.at(subscription_period_end)
    )

    client_account.update(
      custom_attributes: (client_account.custom_attributes || {}).merge(
        'stripe_customer_id' => subscription.customer,
        'stripe_subscription_id' => subscription.id,
        'subscription_status' => subscription.status,
        'plan_name' => 'Marketplace Plan',
        'subscribed_quantity' => subscription['quantity'],
        'subscription_ends_on' => Time.zone.at(subscription_period_end)
      )
    )

    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: client_account).perform
  end

  def process_platform_subscription_updated
    plan = resolve_plan
    return if plan.blank? || account.blank?

    previous_usage = capture_previous_usage
    update_account_attributes(subscription, plan)

    sub_record = Subscription.find_or_initialize_by(account: account)
    was_already_past_due = %w[past_due unpaid].include?(sub_record.status)
    sub_record.update!(
      payment_provider: 'stripe',
      stripe_customer_id: subscription.customer,
      stripe_subscription_id: subscription.id,
      status: subscription.status,
      relationship_type: 'platform',
      stripe_price_id: subscription['plan']['id'],
      stripe_product_id: subscription['plan']['product'],
      plan_name: plan['name'],
      subscribed_quantity: subscription['quantity'],
      current_period_start: Time.zone.at(subscription_period_start),
      current_period_end: Time.zone.at(subscription_period_end),
      cancel_at_period_end: subscription.cancel_at_period_end == true,
      grace_period_ends_at: own_grace_period_ends_at(was_already_past_due, sub_record.grace_period_ends_at)
    )

    if account.is_reseller?
      sub_account_ids = account.sub_accounts.pluck(:id)
      if %w[past_due unpaid].include?(subscription.status)
        # Only start the grace-period clock the first time the reseller goes past
        # due - repeated Stripe retry webhooks must not keep pushing it back, or
        # the enforcer job would never see an expired grace period to act on.
        unless was_already_past_due
          Subscription.where(account_id: sub_account_ids, grace_period_ends_at: nil)
                      .update_all(grace_period_ends_at: PAST_DUE_GRACE_PERIOD.from_now)
        end
      elsif subscription.status == 'active'
        Subscription.where(account_id: sub_account_ids).update_all(grace_period_ends_at: nil)
      end
    end

    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
    record_coupon_redemption!(subscription.metadata) if @event.type == 'customer.subscription.created'

    if billing_period_renewed?
      ActiveRecord::Base.transaction do
        handle_subscription_credits(plan, previous_usage)
        account.reset_response_usage
      end
    elsif plan_changed?
      handle_plan_change_credits(plan, previous_usage)
    end
  end

  def process_subscription_deleted
    if marketplace_subscription?
      process_marketplace_subscription_deleted
    else
      process_platform_subscription_deleted
    end
  end

  def process_marketplace_subscription_deleted
    client_account_id = subscription.metadata['client_account_id']
    client_account = Account.find_by(id: client_account_id)
    return if client_account.blank?

    sub_record = Subscription.find_by(stripe_subscription_id: subscription.id)
    sub_record&.update!(status: 'canceled')

    client_account.update(
      custom_attributes: (client_account.custom_attributes || {}).merge(
        'subscription_status' => 'canceled'
      )
    )
  end

  def process_platform_subscription_deleted
    return if account.blank?

    previous_usage = { responses: account.custom_attributes['captain_responses_usage'].to_i, monthly: current_plan_credits[:responses] }

    sub_record = Subscription.find_by(stripe_subscription_id: subscription.id)
    sub_record&.update!(status: 'canceled', grace_period_ends_at: nil)

    account.with_lock do
      # Drop back to a clean "no active plan" state instead of silently re-subscribing
      # the account to a default plan (which would re-charge the customer's card).
      # The dashboard already redirects admins without a plan_name to billing to pick one.
      updated_attributes = account.custom_attributes.merge('subscription_status' => 'canceled')
      updated_attributes.delete('plan_name')
      account.update!(custom_attributes: updated_attributes)

      # Drop the account back to the free-plan feature/limit baseline now that it
      # has no active plan - otherwise premium features from the cancelled plan
      # would stay enabled indefinitely.
      Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform

      adjust_captain_credits(previous_usage, new_plan_credits: 0)
      account.reset_response_usage
    end
  end

  def process_invoice_payment_succeeded
    invoice = @event.data.object
    return if invoice.subscription.blank?

    stripe_subscription = Stripe::Subscription.retrieve(invoice.subscription)
    return if stripe_subscription.blank?
    return unless stripe_subscription.metadata['relationship_type'] == 'marketplace'

    connected_account_id = stripe_subscription.metadata['connected_account_id']
    connected_account = ConnectedAccount.find_by(id: connected_account_id)
    return if connected_account.blank?
    return unless connected_account.charge_routing == 'separate_charge_transfer'
    return if invoice.charge.blank?

    agency_price = stripe_subscription.metadata['agency_price'].to_f
    currency = invoice.currency

    transfers = Stripe::Transfer.list(source_transaction: invoice.charge)
    return if transfers.data.present?

    Stripe::Transfer.create({
                              amount: (agency_price * 100).to_i,
                              currency: currency.downcase,
                              destination: connected_account.stripe_account_id,
                              source_transaction: invoice.charge,
                              description: "Transfer to reseller for client invoice #{invoice.id}"
                            })
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to transfer funds to reseller for invoice #{invoice.id}: #{e.message}")
  end

  # Keeps a local, queryable record of every invoice Stripe attempts to charge (plan
  # purchases, renewals, Enterprise payment links, and AI-credit top-ups all go through
  # Stripe invoices), so both the user's billing page and Super Admin can show payment
  # history without calling the Stripe API on every page load. Upserts by invoice id so
  # Stripe's occasional duplicate/retry webhooks update the same row instead of creating
  # a second one.
  def record_payment_transaction(status:)
    invoice = @event.data.object
    payer_account = account_for_customer(invoice.customer)
    return if payer_account.blank?

    Enterprise::Billing::RecordPaymentTransactionService.new(
      account: payer_account,
      invoice: invoice,
      status: status
    ).perform
  rescue StandardError => e
    Rails.logger.error("Failed to record payment transaction for invoice #{invoice&.id}: #{e.message}")
  end

  def record_billing_activity_from_invoice(status:)
    invoice = @event.data.object
    payer_account = account_for_customer(invoice.customer)
    return if payer_account.blank?

    message = if status == 'success'
                "Invoice payment succeeded (#{invoice.amount_paid.to_f / 100} #{invoice.currency.upcase})"
              else
                invoice_payment_failure_message(invoice)
              end

    Enterprise::Billing::RecordBillingActivityService.new(
      account: payer_account,
      action: 'invoice_payment',
      status: status,
      message: message,
      error_class: status == 'failed' ? invoice_payment_failure_code(invoice) : nil,
      payment_provider: 'stripe',
      metadata: {
        stripe_invoice_id: invoice.id,
        billing_reason: invoice.billing_reason,
        amount: status == 'success' ? invoice.amount_paid : invoice.amount_due,
        currency: invoice.currency
      }
    ).perform
  rescue StandardError => e
    Rails.logger.error("Failed to record billing activity for invoice #{invoice&.id}: #{e.message}")
  end

  # Hosted Checkout declines (invalid card, authentication failure, etc.) arrive as
  # payment_intent.payment_failed — same signal as Razorpay payment.failed.
  def record_payment_intent_failed_billing_activity
    payment_intent = @event.data.object
    payer_account = account_for_payment_intent(payment_intent)
    return if payer_account.blank?

    error = payment_intent.last_payment_error
    error_code = error&.code.presence || 'payment_intent.payment_failed'
    message = error&.message.presence || 'Stripe payment failed'
    metadata = payment_intent_metadata(payment_intent)
    action = metadata['source'] == 'captain_topup' ? 'topup_checkout' : 'plan_checkout'

    Enterprise::Billing::RecordBillingActivityService.new(
      account: payer_account,
      action: action,
      status: 'failed',
      message: message,
      error_class: error_code,
      payment_provider: 'stripe',
      metadata: {
        event: @event.type,
        stripe_payment_intent_id: payment_intent.id,
        stripe_invoice_id: payment_intent.invoice,
        plan_name: metadata['plan_name'],
        amount: payment_intent.amount,
        currency: payment_intent.currency,
        error_code: error_code,
        error_description: message
      }.compact
    ).perform
  rescue StandardError => e
    Rails.logger.error("[stripe_webhook] failed to record payment_intent.payment_failed activity: #{e.message}")
  end

  def account_for_payment_intent(payment_intent)
    metadata = payment_intent_metadata(payment_intent)
    account = Account.find_by(id: metadata['account_id']) if metadata['account_id'].present?
    return account if account.present?

    account = account_for_customer(payment_intent.customer)
    return account if account.present?

    account_from_payment_intent_invoice(payment_intent)
  end

  def account_from_payment_intent_invoice(payment_intent)
    invoice_id = payment_intent.invoice
    return if invoice_id.blank?

    invoice = Stripe::Invoice.retrieve(invoice_id)
    account_id = invoice.metadata['account_id'].presence ||
                 invoice.parent&.subscription_details&.metadata&.[]('account_id').presence
    return Account.find_by(id: account_id) if account_id.present?

    subscription_id = invoice.subscription.presence ||
                      invoice.parent&.subscription_details&.subscription.presence
    return if subscription_id.blank?

    Subscription.find_by(stripe_subscription_id: subscription_id)&.account
  rescue Stripe::StripeError => e
    Rails.logger.warn("[stripe_webhook] could not resolve account from payment_intent invoice: #{e.message}")
    nil
  end

  def payment_intent_metadata(payment_intent)
    (payment_intent.metadata.respond_to?(:to_hash) ? payment_intent.metadata.to_hash : payment_intent.metadata) || {}
  end

  def invoice_payment_failure_message(invoice)
    invoice.last_finalization_error&.message.presence ||
      'Invoice payment failed'
  end

  def invoice_payment_failure_code(invoice)
    invoice.last_finalization_error&.code.presence || 'invoice.payment_failed'
  end

  def account_for_customer(customer_id)
    account = Account.where("custom_attributes->>'stripe_customer_id' = ?", customer_id).first
    account ||= Subscription.find_by(stripe_customer_id: customer_id)&.account
    account ||= Account.find_by(id: invoice_metadata_account_id) if invoice_event?
    account
  end

  def invoice_event?
    @event.type.start_with?('invoice.')
  end

  # Newer Stripe invoice payloads nest subscription metadata under parent.subscription_details
  # instead of exposing a top-level subscription id we can retrieve.
  def invoice_metadata_account_id
    invoice = @event.data.object
    invoice.metadata['account_id'].presence ||
      invoice.parent&.subscription_details&.metadata&.[]('account_id').presence
  end

  def capture_previous_usage
    { responses: account.custom_attributes['captain_responses_usage'].to_i, monthly: current_plan_credits[:responses] }
  end

  def current_plan_credits
    plan_name = account.custom_attributes['plan_name']
    plan_credits = get_plan_credits(plan_name) if plan_name.present?
    plan_credits || { responses: 0, documents: 0 }
  end

  def update_account_attributes(subscription, plan)
    account.update(
      custom_attributes: account.custom_attributes.merge(
        'stripe_customer_id' => subscription.customer,
        'stripe_price_id' => subscription['plan']['id'],
        'stripe_product_id' => subscription['plan']['product'],
        'plan_name' => plan['name'],
        'subscribed_quantity' => subscription['quantity'],
        'subscription_status' => subscription['status'],
        'subscription_ends_on' => Time.zone.at(subscription_period_end)
      )
    )
  end

  def handle_subscription_credits(plan, previous_usage)
    adjust_captain_credits(previous_usage, new_plan_credits: get_plan_credits(plan['name'])[:responses])
  end

  def adjust_captain_credits(previous_usage, new_plan_credits:)
    current_limits = account.limits || {}
    current_credits = current_limits['captain_responses'].to_i

    consumed_topup_credits = [previous_usage[:responses] - previous_usage[:monthly], 0].max
    updated_credits = [current_credits - consumed_topup_credits - previous_usage[:monthly] + new_plan_credits, 0].max

    Rails.logger.info("Updating captain credits for account #{account.id}: #{current_credits} -> #{updated_credits}")
    account.update!(limits: current_limits.merge('captain_responses' => updated_credits))
  end

  def handle_plan_change_credits(new_plan, previous_usage)
    current_limits = account.limits || {}
    current_credits = current_limits['captain_responses'].to_i

    previous_plan_credits = previous_usage[:monthly]
    new_plan_credits = get_plan_credits(new_plan['name'])[:responses]

    updated_credits = current_credits - previous_plan_credits + new_plan_credits

    account.update!(limits: current_limits.merge('captain_responses' => updated_credits))
  end

  def get_plan_credits(plan_name)
    config = InstallationConfig.find_by(name: CAPTAIN_CLOUD_PLAN_LIMITS).value
    config = JSON.parse(config) if config.is_a?(String)
    config[plan_name.downcase]&.symbolize_keys
  end

  # Starts a PAST_DUE_GRACE_PERIOD grace window the first time a subscription goes
  # past_due/unpaid, and clears it as soon as the status leaves that state (payment
  # recovered, or subscription fully cancelled). Doesn't reset the clock on repeat
  # `customer.subscription.updated` webhooks Stripe fires while still retrying the card.
  def own_grace_period_ends_at(was_already_past_due, current_grace_period_ends_at)
    return current_grace_period_ends_at if was_already_past_due && %w[past_due unpaid].include?(subscription.status)
    return PAST_DUE_GRACE_PERIOD.from_now if %w[past_due unpaid].include?(subscription.status)

    nil
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def previous_attributes
    @previous_attributes ||= JSON.parse((@event.data.previous_attributes || {}).to_json)
  end

  def plan_changed?
    return false if previous_attributes['plan'].blank?

    previous_plan_id = previous_attributes.dig('plan', 'id')
    current_plan_id = subscription['plan']['id']

    previous_plan_id != current_plan_id
  end

  def billing_period_renewed?
    previous_period_start = previous_attributes['current_period_start'] ||
                            previous_attributes.dig('items', 'data', 0, 'current_period_start')
    return false if previous_period_start.blank?

    previous_period_start != subscription_period_start
  end

  # Stripe moved current_period_start/current_period_end off the top-level Subscription
  # object and onto each subscription item once an account is on the newer "flexible"
  # billing_mode (see https://docs.stripe.com/billing/subscriptions/billing-mode).
  # We only ever create single-item subscriptions, so the first item's period is correct.
  def subscription_period_start
    subscription['current_period_start'] || subscription_item&.[]('current_period_start')
  end

  def subscription_period_end
    subscription['current_period_end'] || subscription_item&.[]('current_period_end')
  end

  def subscription_item
    subscription['items']&.[]('data')&.first
  end

  def account
    @account ||= Account.where("custom_attributes->>'stripe_customer_id' = ?", subscription.customer).first
  end

  def marketplace_subscription?
    subscription.metadata['relationship_type'] == 'marketplace'
  end

  def record_coupon_redemption!(metadata)
    code = metadata&.[]('coupon_code').presence
    return if code.blank?

    BillingCoupon.find_by(code: code.to_s.upcase)&.record_redemption!
  end

  # Prefer resolving the plan from the subscription's *current* Price/Product ID -
  # that's always accurate, including when the customer changes plans themselves
  # through the Stripe billing portal (which swaps the subscription's price but does
  # NOT update subscription-level metadata, so trusting stale metadata first would
  # keep reporting whatever plan the subscription was originally created with).
  # Falls back to the `plan_name` metadata stamped by PlanCheckoutService/
  # EnterprisePaymentLinkService only when there's no catalog match - this covers
  # ad-hoc (price_data) Enterprise sessions that have no pre-configured Price/Product ID.
  def resolve_plan
    plan = find_plan(subscription['plan']['product'], subscription['plan']['id']) if subscription['plan'].present?
    return plan if plan.present?

    plan_name = subscription.metadata['plan_name']
    return { 'name' => plan_name } if plan_name.present?

    nil
  end

  def find_plan(product_id, price_id)
    cloud_plans = InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
    cloud_plans.find { |config| config['product_id'].include?(product_id) || config['price_ids'].include?(price_id) }
  end
end
