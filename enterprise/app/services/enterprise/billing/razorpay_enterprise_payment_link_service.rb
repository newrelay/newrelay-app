# Negotiated Enterprise checkout for Indian accounts via Razorpay Subscriptions.
# Creates a one-off Razorpay Plan for the quoted INR amount, then a subscription
# whose short_url is emailed by Super Admin.
class Enterprise::Billing::RazorpayEnterprisePaymentLinkService
  class Error < StandardError; end

  DEFAULT_TOTAL_COUNT = 120

  pattr_initialize [:account!, :monthly_price!, :success_url!, :cancel_url!]

  def perform
    amount_paise = (monthly_price.to_f * 100).round
    raise Error, 'Monthly price must be greater than zero' if amount_paise <= 0

    plan = client.create_plan(
      period: 'monthly',
      interval: 1,
      item: {
        name: "#{account.name} - Enterprise Plan",
        amount: amount_paise,
        currency: 'INR',
        description: 'Enterprise plan (negotiated)'
      },
      notes: {
        account_id: account.id.to_s,
        plan_name: 'Enterprise'
      }
    )

    subscription = client.create_subscription(
      plan_id: plan['id'],
      total_count: DEFAULT_TOTAL_COUNT,
      quantity: 1,
      customer_notify: 1,
      notes: {
        relationship_type: 'platform',
        account_id: account.id.to_s,
        plan_name: 'Enterprise',
        success_url: success_url,
        cancel_url: cancel_url
      }
    )

    pending = account.subscription || account.build_subscription
    pending.assign_attributes(
      payment_provider: 'razorpay',
      relationship_type: 'platform',
      plan_name: 'Enterprise',
      status: subscription['status'].presence || 'created',
      razorpay_subscription_id: subscription['id'],
      subscribed_quantity: 1
    )
    pending.save!

    {
      checkout_url: subscription['short_url'].presence || success_url,
      provider: 'razorpay',
      razorpay_plan_id: plan['id'],
      razorpay_subscription_id: subscription['id']
    }
  end

  private

  def client
    @client ||= Enterprise::Billing::RazorpayClient.new
  end
end
