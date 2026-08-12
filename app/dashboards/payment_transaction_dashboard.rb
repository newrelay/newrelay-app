require 'administrate/base_dashboard'

class PaymentTransactionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    payment_provider: Field::String,
    stripe_customer_id: Field::String,
    stripe_invoice_id: Field::String,
    stripe_charge_id: Field::String,
    amount: Field::Number.with_options(decimals: 2),
    currency: Field::String,
    status: Field::String,
    description: Field::String,
    billing_reason: Field::String,
    hosted_invoice_url: Field::String,
    invoice_pdf: Field::String,
    paid_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    account
    description
    payment_provider
    amount
    currency
    status
    paid_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    payment_provider
    stripe_customer_id
    stripe_invoice_id
    stripe_charge_id
    amount
    currency
    status
    description
    billing_reason
    hosted_invoice_url
    invoice_pdf
    paid_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(payment_transaction)
    "#{payment_transaction.description} - #{payment_transaction.amount} #{payment_transaction.currency}".strip
  end
end
