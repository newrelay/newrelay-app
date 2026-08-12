# Creates/updates the matching Stripe Coupon (and optional Razorpay Offer id
# placeholder) so checkout can attach gateway-native discounts + metadata.
class Enterprise::Billing::SyncBillingCouponService
  class Error < StandardError; end

  pattr_initialize [:coupon!]

  def perform
    sync_stripe_coupon!
    coupon
  end

  private

  def sync_stripe_coupon!
    return if coupon.stripe_coupon_id.present?

    stripe_coupon = Stripe::Coupon.create(stripe_payload)
    coupon.update!(stripe_coupon_id: stripe_coupon.id)
  rescue Stripe::StripeError => e
    raise Error, "Stripe coupon sync failed: #{e.message}"
  end

  def stripe_payload
    payload = {
      name: coupon.name,
      duration: coupon.duration,
      metadata: coupon.gateway_metadata
    }
    payload[:id] = coupon.code if coupon.code.match?(/\A[a-zA-Z0-9_]+\z/)
    payload[:duration_in_months] = coupon.duration_in_months if coupon.duration == 'repeating'
    payload[:max_redemptions] = coupon.max_redemptions if coupon.max_redemptions.present?
    payload[:redeem_by] = coupon.redeem_by.to_i if coupon.redeem_by.present?

    if coupon.discount_type == 'percent'
      payload[:percent_off] = coupon.percent_off.to_f
    else
      payload[:amount_off] = (coupon.amount_off.to_f * 100).round
      payload[:currency] = coupon.currency.to_s.downcase
    end

    payload
  end
end
