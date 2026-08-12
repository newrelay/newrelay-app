require 'administrate/base_dashboard'

class MarketplacePlanPriceDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    currency: Field::String,
    agency_price: Field::Number.with_options(decimals: 2),
    commission_percent: Field::Number.with_options(decimals: 2),
    platform_fee_amount: Field::Number.with_options(decimals: 2),
    total_amount: Field::Number.with_options(decimals: 2),
    stripe_price_id: Field::String,
    stripe_product_id: Field::String,
    razorpay_plan_id: Field::String,
    payment_gateway: Field::String,
    active: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    account
    currency
    payment_gateway
    agency_price
    total_amount
    active
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    currency
    payment_gateway
    agency_price
    commission_percent
    platform_fee_amount
    total_amount
    stripe_price_id
    stripe_product_id
    razorpay_plan_id
    active
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    active
  ].freeze

  def display_resource(price)
    "Marketplace Price ##{price.id} (#{price.currency.upcase} #{price.total_amount})"
  end
end
