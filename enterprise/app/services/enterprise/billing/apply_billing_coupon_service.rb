# Looks up a redeemable BillingCoupon by code for a given checkout context.
class Enterprise::Billing::ApplyBillingCouponService
  class Error < StandardError; end

  pattr_initialize [:code!, :context!] # context: 'plan' | 'topup'

  def perform
    raise Error, 'Coupon code is required' if code.blank?

    coupon = BillingCoupon.find_by(code: code.to_s.strip.upcase)
    raise Error, 'Invalid coupon code' if coupon.blank?
    raise Error, 'This coupon is no longer active' unless coupon.redeemable?
    raise Error, 'This coupon cannot be applied to this purchase' unless applicable?(coupon)

    coupon
  end

  private

  def applicable?(coupon)
    case context.to_s
    when 'plan' then coupon.applies_to_plan?
    when 'topup' then coupon.applies_to_topup?
    else false
    end
  end
end
