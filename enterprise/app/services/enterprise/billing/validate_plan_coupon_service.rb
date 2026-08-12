# Validates an optional billing coupon for a plan purchase and returns pricing.
class Enterprise::Billing::ValidatePlanCouponService
  class Error < StandardError; end

  pattr_initialize [:plan_name!, :country!, :coupon_code]

  def perform
    raise Error, 'Invalid plan name' unless Enterprise::Billing::CloudPlans.purchasable?(plan_name)

    plan = find_plan
    raise Error, 'Plan is not available' if plan.blank? || plan['enabled'] == false

    provider = Enterprise::Billing::PaymentGatewayRegistry.resolve_provider!(country: country)
    base_amount = Enterprise::Billing::CloudPlans.price_for(plan_name, provider)
    currency = Enterprise::Billing::PaymentGatewayRegistry.currency_for(provider)
    coupon = resolve_coupon

    {
      plan_name: plan_name,
      payment_provider: provider,
      currency: currency,
      original_amount: base_amount,
      discounted_amount: coupon.present? ? coupon.discounted_amount(base_amount) : base_amount,
      coupon: coupon_payload(coupon)
    }
  end

  private

  def find_plan
    Enterprise::Billing::CloudPlans.find(plan_name)
  end

  def resolve_coupon
    return nil if coupon_code.blank?

    Enterprise::Billing::ApplyBillingCouponService.new(code: coupon_code, context: 'plan').perform
  end

  def coupon_payload(coupon)
    return nil if coupon.blank?

    {
      code: coupon.code,
      name: coupon.name,
      discount_label: coupon.discount_label,
      discount_type: coupon.discount_type,
      percent_off: coupon.percent_off&.to_f,
      amount_off: coupon.amount_off&.to_f,
      currency: coupon.currency,
      duration: coupon.duration,
      applies_to: coupon.applies_to
    }
  end
end
