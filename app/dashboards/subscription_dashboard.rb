require 'administrate/base_dashboard'

class SubscriptionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    payment_provider: Field::Select.with_options(collection: %w[stripe razorpay]),
    stripe_customer_id: Field::String,
    stripe_subscription_id: Field::String,
    razorpay_customer_id: Field::String,
    razorpay_subscription_id: Field::String,
    status: Field::String,
    relationship_type: Field::String,
    connected_account: Field::BelongsTo,
    application_fee_amount: Field::Number.with_options(decimals: 2),
    stripe_price_id: Field::String,
    stripe_product_id: Field::String,
    plan_name: Field::String,
    subscribed_quantity: Field::Number,
    cancel_at_period_end: Field::Boolean,
    grace_period_ends_at: Field::DateTime,
    current_period_start: Field::DateTime,
    current_period_end: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    account
    plan_name
    payment_provider
    status
    relationship_type
    current_period_end
    grace_period_ends_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    payment_provider
    plan_name
    status
    relationship_type
    subscribed_quantity
    cancel_at_period_end
    current_period_start
    current_period_end
    grace_period_ends_at
    stripe_customer_id
    stripe_subscription_id
    stripe_price_id
    stripe_product_id
    razorpay_customer_id
    razorpay_subscription_id
    connected_account
    application_fee_amount
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    payment_provider
    status
    plan_name
    cancel_at_period_end
    grace_period_ends_at
    application_fee_amount
  ].freeze

  COLLECTION_FILTERS = {
    stripe: ->(resources) { resources.where(payment_provider: 'stripe') },
    razorpay: ->(resources) { resources.where(payment_provider: 'razorpay') }
  }.freeze

  def display_resource(subscription)
    provider = subscription.payment_provider.to_s.upcase
    "Subscription ##{subscription.id} - #{subscription.plan_name} (#{provider})"
  end
end
