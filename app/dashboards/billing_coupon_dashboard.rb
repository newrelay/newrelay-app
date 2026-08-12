require 'administrate/base_dashboard'

class BillingCouponDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    code: Field::String,
    name: Field::String,
    discount_type: Field::Select.with_options(collection: BillingCoupon::DISCOUNT_TYPE_OPTIONS),
    percent_off: Field::Number.with_options(decimals: 2),
    amount_off: Field::Number.with_options(decimals: 2),
    currency: Field::String,
    duration: Field::Select.with_options(collection: BillingCoupon::DURATIONS),
    duration_in_months: Field::Number,
    max_redemptions: Field::Number,
    times_redeemed: Field::Number,
    redeem_by: Field::DateTime,
    active: Field::Boolean,
    applies_to: Field::Select.with_options(collection: BillingCoupon::APPLIES_TO),
    stripe_coupon_id: Field::String,
    razorpay_offer_id: Field::String,
    gateway_sync: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    code
    name
    discount_type
    percent_off
    amount_off
    gateway_sync
    active
    times_redeemed
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    code
    name
    discount_type
    percent_off
    amount_off
    currency
    duration
    duration_in_months
    max_redemptions
    times_redeemed
    redeem_by
    active
    applies_to
    gateway_sync
    stripe_coupon_id
    razorpay_offer_id
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    code
    name
    discount_type
    percent_off
    amount_off
    currency
    duration
    duration_in_months
    max_redemptions
    redeem_by
    active
    applies_to
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(coupon)
    "#{coupon.code} (#{coupon.discount_label})"
  end
end
