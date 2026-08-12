# Creates a real Stripe Checkout session so an account can purchase one of the
# self-serve cloud plans (Hobby/Standard/Business). Requires the plan's Stripe
# Price ID to have been configured in Super Admin > Plan Management first.
#
# Optional coupon_code attaches a Stripe Coupon (synced from BillingCoupon) and
# stamps coupon metadata onto the Checkout session + subscription.
#
# Not used for Enterprise (negotiated - see EnterprisePaymentLinkService). If the
# account already has an active *real* Stripe subscription (as opposed to one set
# via the dev-only bypass_plan), a new Checkout session would create a second,
# duplicate subscription - so we return a Stripe billing portal link instead,
# where Stripe handles the plan change/proration safely.
class Enterprise::Billing::PlanCheckoutService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  class Error < StandardError; end

  pattr_initialize [:account!, :plan_name!, :success_url!, :cancel_url!, :coupon_code]

  def perform
    return { checkout_url: billing_portal_url } if already_on_real_stripe_subscription?
    raise Error, 'This plan is not available for online purchase yet. Please contact support.' if price_id.blank?

    ensure_stripe_coupon! if coupon.present?

    session = Stripe::Checkout::Session.create(session_payload)

    { checkout_url: session.url }
  end

  private

  # Whether creating a new Checkout session would duplicate a subscription Stripe
  # already has on file. This must key off the subscription's Stripe lifecycle
  # (anything short of 'canceled'), not `sub.active?` - the latter also factors in
  # our local grace period, so a past_due subscription whose grace period has
  # expired would otherwise look "inactive" here even though Stripe still has a
  # live (past_due) subscription object that a new Checkout session would duplicate.
  def already_on_real_stripe_subscription?
    sub = account.subscription
    sub.present? && sub.relationship_type == 'platform' && sub.stripe_subscription_id.present? && sub.status != 'canceled'
  end

  def billing_portal_url
    Enterprise::Billing::CreateSessionService.new.create_session(find_or_create_customer, success_url).url
  end

  def session_payload
    payload = {
      mode: 'subscription',
      customer: find_or_create_customer,
      customer_update: { name: 'auto', address: 'auto' },
      billing_address_collection: 'required',
      line_items: [{ price: price_id, quantity: 1 }],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: session_metadata,
      subscription_data: { metadata: session_metadata }
    }
    payload[:discounts] = [{ coupon: coupon.stripe_coupon_id }] if coupon&.stripe_coupon_id.present?
    payload
  end

  def session_metadata
    meta = { relationship_type: 'platform', account_id: account.id.to_s, plan_name: plan_name }
    return meta if coupon.blank?

    meta.merge(coupon.gateway_metadata.stringify_keys)
  end

  def coupon
    return @coupon if defined?(@coupon)
    return @coupon = nil if coupon_code.blank?

    @coupon = Enterprise::Billing::ApplyBillingCouponService.new(code: coupon_code, context: 'plan').perform
  rescue Enterprise::Billing::ApplyBillingCouponService::Error => e
    raise Error, e.message
  end

  def ensure_stripe_coupon!
    return if coupon.stripe_coupon_id.present?

    Enterprise::Billing::SyncBillingCouponService.new(coupon: coupon).perform
    coupon.reload
  end

  def plan
    @plan ||= (InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || [])
              .find { |config| config['name'] == plan_name }
  end

  def price_id
    plan&.dig('price_ids')&.first
  end

  def find_or_create_customer
    customer_id = account.custom_attributes['stripe_customer_id']
    if customer_id.blank?
      customer = Stripe::Customer.create(
        name: account.name,
        email: account.administrators.first&.email,
        metadata: { account_id: account.id.to_s }
      )
      customer_id = customer.id
      account.update!(custom_attributes: (account.custom_attributes || {}).merge('stripe_customer_id' => customer_id))
    end
    customer_id
  end
end
