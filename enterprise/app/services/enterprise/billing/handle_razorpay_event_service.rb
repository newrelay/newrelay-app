class Enterprise::Billing::HandleRazorpayEventService
  def perform(event:)
    @event = event.with_indifferent_access
    event_id = @event[:event] || @event[:id]
    payload_entity = @event.dig(:payload) || {}

    return if event_id.present? && ProcessedWebhookEvent.exists?(stripe_event_id: "razorpay_#{event_id}_#{entity_fingerprint(payload_entity)}")

    case @event[:event]
    when 'subscription.activated', 'subscription.charged'
      process_subscription_active(payload_entity)
      record_subscription_billing_activity(payload_entity, status: 'success')
    when 'subscription.pending', 'subscription.halted'
      process_subscription_past_due(payload_entity)
      record_subscription_billing_activity(payload_entity, status: 'failed')
    when 'subscription.cancelled', 'subscription.completed'
      process_subscription_deleted(payload_entity)
    when 'payment_link.paid', 'payment.captured'
      process_topup_payment(payload_entity)
    when 'payment.failed'
      record_payment_failed_billing_activity(payload_entity)
    end

    return if event_id.blank?

    ProcessedWebhookEvent.create!(
      stripe_event_id: "razorpay_#{event_id}_#{entity_fingerprint(payload_entity)}",
      event_type: @event[:event]
    )
  rescue ActiveRecord::RecordNotUnique
    # Concurrent duplicate webhook - safe to ignore.
  end

  private

  def entity_fingerprint(payload_entity)
    subscription_payload(payload_entity)[:id].presence ||
      payment_link_payload(payload_entity)[:id].presence ||
      payment_payload(payload_entity)[:id].presence ||
      SecureRandom.hex(4)
  end

  def subscription_payload(payload_entity)
    (payload_entity.dig(:subscription, :entity) || {}).with_indifferent_access
  end

  def payment_payload(payload_entity)
    (payload_entity.dig(:payment, :entity) || {}).with_indifferent_access
  end

  def payment_link_payload(payload_entity)
    (payload_entity.dig(:payment_link, :entity) || {}).with_indifferent_access
  end

  def process_subscription_active(payload_entity)
    razorpay_sub = subscription_payload(payload_entity)
    return if razorpay_sub[:id].blank?

    if razorpay_sub.dig(:notes, :relationship_type) == 'marketplace'
      process_marketplace_subscription_active(razorpay_sub)
      transfer_agency_share!(razorpay_sub, payload_entity) if @event[:event] == 'subscription.charged'
      return
    end

    account = find_account_from_notes(razorpay_sub)
    return if account.blank?

    plan_name = razorpay_sub.dig(:notes, :plan_name).presence || account.subscription&.plan_name
    return if plan_name.blank?

    subscription = account.subscription || account.build_subscription
    subscription.assign_attributes(
      payment_provider: 'razorpay',
      relationship_type: 'platform',
      plan_name: plan_name,
      status: 'active',
      razorpay_subscription_id: razorpay_sub[:id],
      razorpay_customer_id: razorpay_sub[:customer_id],
      subscribed_quantity: razorpay_sub[:quantity].presence || 1,
      current_period_start: time_at(razorpay_sub[:current_start]),
      current_period_end: time_at(razorpay_sub[:current_end]),
      grace_period_ends_at: nil
    )
    subscription.save!

    account.update!(
      custom_attributes: (account.custom_attributes || {}).merge(
        'plan_name' => plan_name,
        'subscription_status' => 'active',
        'payment_provider' => 'razorpay',
        'razorpay_customer_id' => razorpay_sub[:customer_id],
        'subscription_ends_on' => time_at(razorpay_sub[:current_end])&.iso8601
      ).compact
    )

    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
    record_coupon_redemption!(razorpay_sub[:notes]) if @event[:event] == 'subscription.activated'
  end

  def process_marketplace_subscription_active(razorpay_sub)
    client_account = Account.find_by(id: razorpay_sub.dig(:notes, :client_account_id))
    return if client_account.blank?

    plan_price = MarketplacePlanPrice.find_by(id: razorpay_sub.dig(:notes, :marketplace_plan_price_id))
    connected_account_id = razorpay_sub.dig(:notes, :connected_account_id)

    subscription = client_account.subscription || client_account.build_subscription
    subscription.assign_attributes(
      payment_provider: 'razorpay',
      relationship_type: 'marketplace',
      connected_account_id: connected_account_id,
      plan_name: 'Marketplace Plan',
      status: 'active',
      razorpay_subscription_id: razorpay_sub[:id],
      application_fee_amount: plan_price&.platform_fee_amount,
      subscribed_quantity: razorpay_sub[:quantity].presence || 1,
      current_period_start: time_at(razorpay_sub[:current_start]),
      current_period_end: time_at(razorpay_sub[:current_end]),
      grace_period_ends_at: nil
    )
    subscription.save!

    client_account.update!(
      custom_attributes: (client_account.custom_attributes || {}).merge(
        'plan_name' => 'Marketplace Plan',
        'subscription_status' => 'active',
        'payment_provider' => 'razorpay',
        'subscription_ends_on' => time_at(razorpay_sub[:current_end])&.iso8601
      ).compact
    )

    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: client_account).perform
  end

  # Mirror Stripe India's separate_charge_transfer: platform collected full amount,
  # now push the reseller's agency_price to their Route linked account.
  def transfer_agency_share!(razorpay_sub, payload_entity)
    agency_price = razorpay_sub.dig(:notes, :agency_price).to_f
    return if agency_price <= 0

    connected_account = ConnectedAccount.find_by(id: razorpay_sub.dig(:notes, :connected_account_id))
    return if connected_account&.razorpay_account_id.blank?

    payment = payment_payload(payload_entity)
    payment_id = payment[:id]
    return if payment_id.blank?

    Enterprise::Billing::RazorpayClient.new.create_transfer(
      account: connected_account.razorpay_account_id,
      amount: (agency_price * 100).to_i,
      currency: (payment[:currency].presence || 'INR').to_s.upcase,
      notes: {
        marketplace_plan_price_id: razorpay_sub.dig(:notes, :marketplace_plan_price_id).to_s,
        client_account_id: razorpay_sub.dig(:notes, :client_account_id).to_s,
        razorpay_payment_id: payment_id
      }
    )
  rescue Enterprise::Billing::RazorpayClient::Error => e
    Rails.logger.error("[razorpay_marketplace] transfer failed for sub #{razorpay_sub[:id]}: #{e.message}")
  end

  def process_subscription_past_due(payload_entity)
    razorpay_sub = subscription_payload(payload_entity)
    return if razorpay_sub[:id].blank?

    subscription = Subscription.find_by(razorpay_subscription_id: razorpay_sub[:id])
    return if subscription.blank?

    was_already_past_due = %w[past_due unpaid].include?(subscription.status)
    subscription.update!(
      status: 'past_due',
      grace_period_ends_at: was_already_past_due ? subscription.grace_period_ends_at : 7.days.from_now
    )

    account = subscription.account
    account.update!(
      custom_attributes: (account.custom_attributes || {}).merge('subscription_status' => 'past_due')
    )
  end

  def record_subscription_billing_activity(payload_entity, status:)
    razorpay_sub = subscription_payload(payload_entity)
    return if razorpay_sub[:id].blank?

    subscription = Subscription.find_by(razorpay_subscription_id: razorpay_sub[:id])
    account = subscription&.account || find_account_from_notes(razorpay_sub)
    return if account.blank?

    message = if status == 'success'
                "Razorpay subscription #{@event[:event]}"
              else
                "Razorpay subscription payment failed (#{@event[:event]})"
              end

    Enterprise::Billing::RecordBillingActivityService.new(
      account: account,
      action: 'subscription_payment',
      status: status,
      message: message,
      error_class: status == 'failed' ? @event[:event] : nil,
      payment_provider: 'razorpay',
      metadata: {
        razorpay_subscription_id: razorpay_sub[:id],
        plan_name: razorpay_sub.dig(:notes, :plan_name),
        event: @event[:event],
        subscription_status: razorpay_sub[:status]
      }
    ).perform
  rescue StandardError => e
    Rails.logger.error("[razorpay_webhook] failed to record billing activity: #{e.message}")
  end

  # First-checkout / hosted-page payment failures arrive as payment.failed, not
  # subscription.pending/halted. Log them so Super Admin can see invalid card/UPI attempts.
  def record_payment_failed_billing_activity(payload_entity)
    payment = payment_payload(payload_entity)
    return if payment[:id].blank?

    account = find_account_from_payment(payment)
    return if account.blank?

    error_code = payment[:error_code].presence || 'payment.failed'
    error_description = payment[:error_description].presence ||
                        payment[:error_reason].presence ||
                        'Razorpay payment failed'

    action = if payment.dig(:notes, :source) == 'captain_topup'
               'topup_checkout'
             else
               'plan_checkout'
             end

    Enterprise::Billing::RecordBillingActivityService.new(
      account: account,
      action: action,
      status: 'failed',
      message: error_description,
      error_class: error_code,
      payment_provider: 'razorpay',
      metadata: {
        event: @event[:event],
        razorpay_payment_id: payment[:id],
        razorpay_subscription_id: payment[:subscription_id],
        razorpay_order_id: payment[:order_id],
        plan_name: payment.dig(:notes, :plan_name),
        method: payment[:method],
        amount: payment[:amount],
        currency: payment[:currency],
        error_code: error_code,
        error_description: error_description
      }.compact
    ).perform
  rescue StandardError => e
    Rails.logger.error("[razorpay_webhook] failed to record payment.failed activity: #{e.message}")
  end

  def find_account_from_payment(payment)
    notes = (payment[:notes] || {}).with_indifferent_access
    account = Account.find_by(id: notes[:account_id]) if notes[:account_id].present?
    return account if account.present?

    account = Account.find_by(id: notes[:client_account_id]) if notes[:client_account_id].present?
    return account if account.present?

    if payment[:subscription_id].present?
      subscription = Subscription.find_by(razorpay_subscription_id: payment[:subscription_id])
      return subscription.account if subscription.present?
    end

    nil
  end

  def process_subscription_deleted(payload_entity)
    razorpay_sub = subscription_payload(payload_entity)
    return if razorpay_sub[:id].blank?

    subscription = Subscription.find_by(razorpay_subscription_id: razorpay_sub[:id])
    account = subscription&.account || find_account_from_notes(razorpay_sub)
    return if account.blank?

    subscription&.update!(status: 'canceled', grace_period_ends_at: nil)

    updated_attributes = (account.custom_attributes || {}).merge('subscription_status' => 'canceled')
    updated_attributes.delete('plan_name')
    account.update!(custom_attributes: updated_attributes)

    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
  end

  def process_topup_payment(payload_entity)
    notes = topup_notes(payload_entity)
    return if notes[:source] != 'captain_topup'

    account = Account.find_by(id: notes[:account_id])
    return if account.blank?

    credits = notes[:credits].to_i
    return if credits <= 0

    payment = payment_payload(payload_entity)
    payment_link = payment_link_payload(payload_entity)
    external_id = payment[:id].presence || payment_link[:id].presence
    return if external_id.blank?

    amount = notes[:amount].presence&.to_f
    amount ||= payment[:amount].to_i / 100.0 if payment[:amount].present?
    currency = (notes[:currency].presence || payment[:currency].presence || 'inr').downcase

    Enterprise::Billing::TopupFulfillmentService.new(account: account).fulfill(
      credits: credits,
      amount_cents: ((amount || 0) * 100).to_i,
      currency: currency,
      external_payment_id: external_id
    )

    record_topup_payment_transaction(account, payment, payment_link, credits, amount, currency)
  end

  def topup_notes(payload_entity)
    payment_link_payload(payload_entity)[:notes].presence ||
      payment_payload(payload_entity)[:notes].presence ||
      {}
  end

  def record_topup_payment_transaction(account, payment, payment_link, credits, amount, currency)
    external_id = payment[:id].presence || payment_link[:id].presence
    return if external_id.blank?

    PaymentTransaction.find_or_initialize_by(stripe_invoice_id: external_id).update!(
      account: account,
      stripe_customer_id: payment[:customer_id],
      amount: amount,
      currency: currency,
      status: 'succeeded',
      description: "Captain AI Credits - #{credits} credits",
      billing_reason: 'captain_topup',
      paid_at: time_at(payment[:created_at]) || Time.current,
      hosted_invoice_url: payment_link[:short_url]
    )
  rescue StandardError => e
    Rails.logger.error("Failed to record Razorpay topup payment #{external_id}: #{e.message}")
  end

  def find_account_from_notes(entity)
    account_id = entity.dig(:notes, :account_id)
    Account.find_by(id: account_id) ||
      Subscription.find_by(razorpay_subscription_id: entity[:id])&.account
  end

  def record_coupon_redemption!(notes)
    code = notes&.with_indifferent_access&.[](:coupon_code).presence
    return if code.blank?

    BillingCoupon.find_by(code: code.to_s.upcase)&.record_redemption!
  end

  def time_at(epoch)
    return if epoch.blank?

    Time.zone.at(epoch.to_i)
  end
end
