# Logs when a customer returns from hosted checkout without completing payment.
# Webhooks cover failed payment attempts; this covers cancel/back and unpaid returns.
class Enterprise::Billing::RecordCheckoutAbandonmentService
  CHECKOUT_ACTIONS = %w[plan_checkout topup_checkout marketplace_checkout].freeze

  pattr_initialize [:account!, :return_type!, :checkout_type!, { user: nil, checkout_ref: nil, payment_provider: nil }]

  def perform
    return false unless CHECKOUT_ACTIONS.include?(checkout_type)
    # success is often "paid, webhook still in flight" — never treat that as abandonment.
    return false unless return_type == 'cancel'
    return false if duplicate_log?

    Enterprise::Billing::RecordBillingActivityService.new(
      account: account,
      user: user,
      action: checkout_type,
      status: 'failed',
      message: abandonment_message,
      error_class: 'checkout_abandoned',
      payment_provider: resolved_payment_provider,
      metadata: abandonment_metadata
    ).perform
    true
  end

  private

  def duplicate_log?
    return false if checkout_ref.blank?

    BillingActivityLog.where(account_id: account.id, error_class: 'checkout_abandoned')
                      .exists?(["metadata->>'checkout_ref' = ?", checkout_ref])
  end

  def abandonment_message
    "Checkout abandoned (#{checkout_type.tr('_', ' ')})"
  end

  def abandonment_metadata
    subscription = account.subscription
    {
      checkout_ref: checkout_ref,
      return_type: return_type,
      plan_name: subscription&.plan_name,
      razorpay_subscription_id: subscription&.razorpay_subscription_id,
      stripe_subscription_id: subscription&.stripe_subscription_id,
      subscription_status: subscription&.status
    }.compact
  end

  def resolved_payment_provider
    payment_provider.presence ||
      account.subscription&.payment_provider.presence ||
      account.custom_attributes['payment_provider']
  end
end
