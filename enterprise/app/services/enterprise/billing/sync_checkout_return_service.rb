# Fulfills a plan purchase when the customer returns from Stripe/Razorpay,
# so the paywall does not wait solely on a delayed or missing webhook.
class Enterprise::Billing::SyncCheckoutReturnService
  PLAN_CHECKOUT_TYPES = %w[plan_checkout marketplace_checkout].freeze
  RAZORPAY_PAID_STATUSES = %w[active authenticated].freeze

  pattr_initialize [:account!, :return_type!, :checkout_type!, { checkout_session_id: nil }]

  def perform
    return false unless return_type == 'success'
    return false unless PLAN_CHECKOUT_TYPES.include?(checkout_type)
    return false if already_unlocked?

    if stripe_session_id?
      sync_stripe_session
    else
      sync_razorpay_subscription
    end
  rescue Stripe::StripeError, Enterprise::Billing::RazorpayClient::Error => e
    Rails.logger.warn("[checkout_return] sync failed account=#{account.id}: #{e.class}: #{e.message}")
    false
  end

  private

  def already_unlocked?
    account.custom_attributes['plan_name'].present? && account.subscription&.active?
  end

  def stripe_session_id?
    checkout_session_id.to_s.start_with?('cs_')
  end

  def sync_stripe_session
    session = Stripe::Checkout::Session.retrieve(checkout_session_id, { expand: ['subscription'] })
    return false unless session_belongs_to_account?(session)

    stripe_sub = stripe_subscription_from(session)
    return false if stripe_sub.blank?

    event = Stripe::Event.construct_from(
      id: "checkout_return_#{session.id}",
      object: 'event',
      type: 'customer.subscription.updated',
      data: { object: stripe_sub.to_hash }
    )
    Enterprise::Billing::HandleStripeEventService.new.perform(event: event)
    true
  end

  def session_belongs_to_account?(session)
    metadata = session_metadata(session)
    return true if metadata['account_id'].to_s == account.id.to_s
    return true if metadata['client_account_id'].to_s == account.id.to_s

    customer_id = session.try(:customer) || session['customer']
    customer_id.present? && (
      account.custom_attributes['stripe_customer_id'] == customer_id ||
      account.subscription&.stripe_customer_id == customer_id
    )
  end

  def session_metadata(session)
    raw = session.try(:metadata) || session['metadata'] || {}
    raw.respond_to?(:to_hash) ? raw.to_hash.stringify_keys : raw.to_h.stringify_keys
  end

  def stripe_subscription_from(session)
    expanded = session.try(:subscription) || session['subscription']
    return expanded if expanded.respond_to?(:to_hash) && !expanded.is_a?(String)
    return if expanded.blank?

    Stripe::Subscription.retrieve(expanded)
  end

  def sync_razorpay_subscription
    sub = account.subscription
    return false if sub.blank? || sub.razorpay_subscription_id.blank?

    razorpay_sub = Enterprise::Billing::RazorpayClient.new.fetch_subscription(sub.razorpay_subscription_id)
    return false unless RAZORPAY_PAID_STATUSES.include?(razorpay_sub['status'].to_s)

    Enterprise::Billing::HandleRazorpayEventService.new.perform(
      event: {
        event: 'subscription.activated',
        id: "checkout_return_#{razorpay_sub['id']}",
        payload: { subscription: { entity: razorpay_sub } }
      }
    )
    true
  end
end
