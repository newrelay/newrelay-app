class Enterprise::Api::V1::AccountsController < Api::BaseController
  include BillingHelper
  include Enterprise::BillingActivityLogging
  before_action :fetch_account
  before_action :check_authorization
  before_action :check_cloud_env, only: [:toggle_deletion]

  def subscription
    if stripe_customer_id.blank? && @account.custom_attributes['is_creating_customer'].blank?
      @account.update(custom_attributes: { is_creating_customer: true })
      Enterprise::CreateStripeCustomerJob.perform_later(@account)
    end
    head :no_content
  end

  def limits
    limits = default_limits

    # Only fall back to Chatwoot's hardcoded free-tier caps when the custom plan
    # matrix has not written any limits for this account yet.
    if default_plan?(@account) && @account.limits.blank?
      limits.merge!(
        'conversation' => {
          'allowed' => 500,
          'consumed' => conversations_this_month(@account)
        },
        'non_web_inboxes' => {
          'allowed' => 0,
          'consumed' => non_web_inboxes(@account)
        },
        'agents' => {
          'allowed' => 2,
          'consumed' => agents(@account)
        }
      )
    end

    # include id in response to ensure that the store can be updated on the frontend
    render json: { id: @account.id, limits: limits }, status: :ok
  end

  def checkout
    if locked_payment_provider == 'razorpay'
      return render json: {
        error: 'This subscription is managed through Razorpay. Cancel it before using the Stripe billing portal.'
      }, status: :unprocessable_entity
    end

    return create_stripe_billing_session(stripe_customer_id) if stripe_customer_id.present?

    render_invalid_billing_details
  end

  def toggle_deletion
    action_type = params[:action_type]

    case action_type
    when 'delete'
      mark_for_deletion
    when 'undelete'
      unmark_for_deletion
    else
      render json: { error: 'Invalid action_type. Must be either "delete" or "undelete"' }, status: :unprocessable_entity
    end
  end

  def topup_checkout
    return render_payment_failure('topup_checkout', I18n.t('errors.topup.credits_required')) if params[:credits].blank?

    provider = checkout_payment_provider!
    result = if provider == 'razorpay'
               Enterprise::Billing::RazorpayTopupCheckoutService.new(
                 account: @account,
                 success_url: params[:success_url].presence || frontend_billing_url,
                 cancel_url: params[:cancel_url].presence || frontend_billing_url
               ).create_checkout_session(credits: params[:credits].to_i)
             else
               Enterprise::Billing::TopupCheckoutService.new(
                 account: @account,
                 success_url: params[:success_url].presence || frontend_billing_url,
                 cancel_url: params[:cancel_url].presence || frontend_billing_url
               ).create_checkout_session(credits: params[:credits].to_i).merge(provider: 'stripe')
             end

    log_billing_success(
      'topup_checkout',
      "Checkout session created for #{params[:credits]} credits",
      payment_provider: provider,
      metadata: { checkout_id: result[:id] || result[:subscription_id], credits: params[:credits].to_i }
    )
    render json: result
  rescue Enterprise::Billing::PaymentGatewayRegistry::UnsupportedCountryError => e
    render_payment_failure('topup_checkout', e.message, error_class: e.class.name, payment_provider: checkout_payment_provider)
  rescue Enterprise::Billing::TopupCheckoutService::Error,
         Enterprise::Billing::RazorpayTopupCheckoutService::Error,
         Enterprise::Billing::RazorpayClient::Error,
         Stripe::StripeError => e
    render_payment_failure('topup_checkout', e.message, error_class: e.class.name, payment_provider: checkout_payment_provider)
  end

  def cancel_subscription
    provider = locked_payment_provider || @account.subscription&.payment_provider
    if provider == 'razorpay'
      result = Enterprise::Billing::RazorpayCancelSubscriptionService.new(account: @account).perform(
        cancel_at_cycle_end: params[:cancel_at_cycle_end] != false && params[:cancel_at_cycle_end] != 'false'
      )
      log_billing_success(
        'cancel_subscription',
        'Subscription cancellation scheduled',
        payment_provider: 'razorpay',
        metadata: result.to_h.slice('cancel_at_cycle_end', 'current_period_end').compact
      )
      return render json: result
    end

    return create_stripe_billing_session(stripe_customer_id) if stripe_customer_id.present?

    render_invalid_billing_details
  rescue Enterprise::Billing::RazorpayCancelSubscriptionService::Error,
         Enterprise::Billing::RazorpayClient::Error => e
    render_payment_failure('cancel_subscription', e.message, error_class: e.class.name, payment_provider: provider)
  end

  def checkout_return
    Enterprise::Billing::RecordCheckoutAbandonmentService.new(
      account: @account,
      user: current_user,
      return_type: params[:return_type],
      checkout_type: params[:checkout_type],
      checkout_ref: params[:checkout_ref],
      payment_provider: checkout_return_payment_provider
    ).perform

    head :no_content
  end

  def validate_coupon
    return render_payment_failure('validate_coupon', 'Invalid plan name') unless Enterprise::Billing::CloudPlans.purchasable?(params[:plan_name])

    locked_provider = locked_payment_provider
    country = normalize_billing_country(params[:country])

    if locked_provider.present?
      country = country_for_provider(locked_provider)
    elsif country.blank?
      return render_payment_failure('validate_coupon', 'Country is required')
    end

    result = Enterprise::Billing::ValidatePlanCouponService.new(
      plan_name: params[:plan_name],
      country: country,
      coupon_code: params[:coupon_code].presence
    ).perform

    log_billing_success(
      'validate_coupon',
      params[:coupon_code].present? ? "Coupon applied for #{params[:plan_name]} plan" : "Pricing loaded for #{params[:plan_name]} plan",
      payment_provider: locked_provider || provider_for_country(country),
      metadata: { plan_name: params[:plan_name], country: country, coupon_code: params[:coupon_code].presence }
    )
    render json: result
  rescue Enterprise::Billing::PaymentGatewayRegistry::UnsupportedCountryError => e
    render_payment_failure('validate_coupon', e.message, error_class: e.class.name, payment_provider: locked_payment_provider)
  rescue Enterprise::Billing::ValidatePlanCouponService::Error,
         Enterprise::Billing::ApplyBillingCouponService::Error => e
    render_payment_failure('validate_coupon', e.message, error_class: e.class.name, payment_provider: locked_payment_provider)
  end

  def plan_checkout
    return render_payment_failure('plan_checkout', 'Invalid plan name') unless Enterprise::Billing::CloudPlans.purchasable?(params[:plan_name])

    locked_provider = locked_payment_provider
    country = normalize_billing_country(params[:country])

    if locked_provider.present?
      requested_provider = provider_for_country(country.presence || country_for_provider(locked_provider))
      if requested_provider.blank?
        return render_payment_failure(
          'plan_checkout',
          "Online billing is not available for #{country}. Please contact support.",
          payment_provider: locked_provider
        )
      end
      if requested_provider != locked_provider
        return render_payment_failure(
          'plan_checkout',
          "Your active plan is billed through #{locked_provider.capitalize}. Cancel it before switching payment gateways.",
          payment_provider: locked_provider
        )
      end
      country = country_for_provider(locked_provider)
    else
      return render_payment_failure('plan_checkout', 'Country is required') if country.blank?

      persist_billing_country!(country)
    end

    checkout_args = {
      account: @account,
      plan_name: params[:plan_name],
      success_url: params[:success_url].presence || frontend_billing_url,
      cancel_url: params[:cancel_url].presence || frontend_billing_url,
      coupon_code: params[:coupon_code].presence
    }

    provider = provider_for_country!(country)
    result = if provider == 'razorpay'
               Enterprise::Billing::RazorpayPlanCheckoutService.new(**checkout_args).perform
             else
               Enterprise::Billing::PlanCheckoutService.new(**checkout_args).perform.merge(provider: 'stripe')
             end

    log_billing_success(
      'plan_checkout',
      "Checkout session created for #{params[:plan_name]} plan",
      payment_provider: provider,
      metadata: {
        plan_name: params[:plan_name],
        country: country,
        checkout_id: result[:id] || result[:subscription_id],
        coupon_code: params[:coupon_code].presence
      }.compact
    )
    render json: result
  rescue Enterprise::Billing::PaymentGatewayRegistry::UnsupportedCountryError => e
    render_payment_failure('plan_checkout', e.message, error_class: e.class.name)
  rescue Enterprise::Billing::PlanCheckoutService::Error,
         Enterprise::Billing::RazorpayPlanCheckoutService::Error,
         Enterprise::Billing::ApplyBillingCouponService::Error,
         Enterprise::Billing::RazorpayClient::Error,
         Stripe::StripeError => e
    Rails.logger.error("[plan_checkout] account=#{@account.id} plan=#{params[:plan_name]} #{e.class}: #{e.message}")
    render_payment_failure('plan_checkout', e.message, error_class: e.class.name,
                                                       payment_provider: provider_for_country(normalize_billing_country(params[:country])))
  rescue StandardError => e
    Rails.logger.error("[plan_checkout] account=#{@account.id} plan=#{params[:plan_name]} UNEXPECTED #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
    render_payment_failure('plan_checkout', "Checkout failed: #{e.message}", error_class: e.class.name)
  end

  def bypass_plan
    plan_name = params[:plan_name]
    return render json: { error: 'Invalid plan name' }, status: :unprocessable_entity unless %w[Hobby Standard Business
                                                                                                Enterprise].include?(plan_name)

    @account.update_column(:custom_attributes, @account.custom_attributes.merge('plan_name' => plan_name))
    @account.reload

    # Ensure a subscription record exists so it shows up in Super Admin
    subscription = @account.subscription || @account.build_subscription
    subscription.assign_attributes(
      plan_name: plan_name,
      status: 'active',
      relationship_type: 'platform',
      subscribed_quantity: 1,
      current_period_start: Time.current,
      current_period_end: 10.years.from_now
    )
    subscription.save!

    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: @account).perform

    render json: {
      message: "Plan updated to #{plan_name}",
      limits: @account.limits,
      custom_attributes: @account.custom_attributes
    }, status: :ok
  end

  def transactions
    # Past invoices (paid before this feature shipped, or while stripe_customer_id was
    # missing/stale) are pulled from Stripe on first load so the billing page is not empty.
    Enterprise::Billing::SyncPaymentTransactionsService.new(account: @account).perform if @account.payment_transactions.none?

    payments = @account.payment_transactions.recent_first.limit(100)

    render json: payments.as_json(
      only: %i[id amount currency status description billing_reason paid_at created_at hosted_invoice_url invoice_pdf]
    )
  end

  # Public-facing plan catalog for the "Change plan" picker - only exposes what a
  # customer needs to compare plans (name, seat price, whether it's purchasable).
  # Deliberately omits Stripe product_id/price_ids, which are internal wiring details.
  def plans
    render json: {
      plans: Enterprise::Billing::CloudPlans.public_catalog,
      payment_gateways: Enterprise::Billing::PaymentGatewayRegistry.public_config
    }
  end

  def enterprise_inquiry
    inquiry = enterprise_inquiry_params.merge(
      'requested_at' => Time.current.iso8601,
      'requested_by' => current_user.email
    )

    Enterprise::Billing::EnterpriseInquiryAttributes.save_enterprise_inquiry!(@account, inquiry)

    AdministratorNotifications::EnterpriseInquiryMailer.with(account: @account)
                                                       .submitted(account: @account, user: current_user, inquiry: inquiry)
                                                       .deliver_later

    render json: { message: 'Thanks! Our team will reach out to discuss your Enterprise plan shortly.' }, status: :ok
  end

  def cancel_enterprise_inquiry
    cleared = Enterprise::Billing::ClearEnterpriseInquiryService.new(account: @account).perform
    return render json: { error: 'No pending Enterprise inquiry found.' }, status: :not_found unless cleared

    render json: { message: 'Enterprise inquiry cancelled. You can choose a self-serve plan anytime.' }, status: :ok
  end

  private

  def enterprise_inquiry_params
    params.permit(:company_size, :team_size, :message, desired_features: []).to_h
  end

  def check_cloud_env
    render json: { error: 'Not found' }, status: :not_found unless ChatwootApp.chatwoot_cloud?
  end

  def default_limits
    {
      'conversation' => {
        'allowed' => plan_limit('conversations'),
        'consumed' => conversations_this_month(@account)
      },
      'non_web_inboxes' => {
        'allowed' => @account.usage_limits[:inboxes] || @account.usage_limits[:non_web_inboxes],
        'consumed' => non_web_inboxes(@account)
      },
      'agents' => {
        'allowed' => @account.usage_limits[:agents],
        'consumed' => agents(@account)
      },
      'contacts' => {
        'allowed' => plan_limit('contacts'),
        'consumed' => @account.contacts.count
      },
      'automations' => {
        'allowed' => plan_limit('automations'),
        'consumed' => @account.automation_rules.count
      },
      't3_subaccounts' => {
        'allowed' => plan_limit('t3_subaccounts'),
        'consumed' => @account.sub_accounts.count
      },
      'captain' => @account.usage_limits[:captain],
      # nil means unlimited retention (Enterprise or no plan matrix entry for this account's plan).
      'data_retention_months' => @account.limits['data_retention_months']
    }
  end

  # A missing key in account.limits means the plan matrix left this resource
  # unlimited (ReconcilePlanFeaturesService drops nil limit_value entries),
  # so fall back to the "no limit" sentinel instead of 0.
  def plan_limit(key)
    @account.limits[key] || ChatwootApp.max_limit
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def stripe_customer_id
    @account.custom_attributes['stripe_customer_id']
  end

  def frontend_billing_url
    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/app/accounts/#{@account.id}/settings/billing"
  end

  def normalize_billing_country(value)
    value.to_s.strip.upcase.presence
  end

  def india_country?(country)
    country == 'IN'
  end

  def provider_for_country(country)
    Enterprise::Billing::PaymentGatewayRegistry.resolve_provider(country: country)
  end

  def provider_for_country!(country)
    Enterprise::Billing::PaymentGatewayRegistry.resolve_provider!(country: country)
  end

  def country_for_provider(provider)
    Enterprise::Billing::PaymentGatewayRegistry.default_country_for(provider)
  end

  # An active (or still-grace) subscription locks the account to one gateway so
  # customers cannot open a second Stripe/Razorpay subscription in parallel.
  def locked_payment_provider
    sub = @account.subscription
    return if sub.blank?
    return unless sub.active? || %w[past_due unpaid].include?(sub.status)

    sub.payment_provider.presence || @account.custom_attributes['payment_provider']
  end

  def checkout_payment_provider
    locked_payment_provider.presence ||
      provider_for_country(@account.custom_attributes['billing_country'])
  end

  def checkout_return_payment_provider
    checkout_payment_provider
  end

  def checkout_payment_provider!
    locked = locked_payment_provider
    return locked if locked.present?

    provider_for_country!(@account.custom_attributes['billing_country'])
  end

  def persist_billing_country!(country)
    @account.update!(
      custom_attributes: (@account.custom_attributes || {}).merge('billing_country' => country)
    )
  end

  def mark_for_deletion
    reason = 'manual_deletion'

    if @account.mark_for_deletion(reason)
      cancel_cloud_subscriptions_for_deletion

      render json: { message: 'Account marked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def unmark_for_deletion
    if @account.unmark_for_deletion
      render json: { message: 'Account unmarked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def render_invalid_billing_details
    render_could_not_create_error('Please subscribe to a plan before viewing the billing details')
  end

  def create_stripe_billing_session(customer_id)
    session = Enterprise::Billing::CreateSessionService.new.create_session(customer_id, frontend_billing_url)
    render_redirect_url(session.url)
  end

  def cancel_cloud_subscriptions_for_deletion
    Enterprise::Billing::CancelCloudSubscriptionsService.new(account: @account).perform
  rescue Stripe::StripeError => e
    Rails.logger.warn("Failed to cancel cloud subscriptions for account #{@account.id}: #{e.class} - #{e.message}")
  end

  def render_redirect_url(redirect_url)
    render json: { redirect_url: redirect_url }
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
