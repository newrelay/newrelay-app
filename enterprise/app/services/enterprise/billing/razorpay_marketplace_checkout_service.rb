# Marketplace client checkout via Razorpay Subscriptions. Platform collects the
# full amount; agency share is transferred to the reseller's Route linked account
# when subscription.charged fires (see HandleRazorpayEventService).
class Enterprise::Billing::RazorpayMarketplaceCheckoutService
  class Error < StandardError; end

  DEFAULT_TOTAL_COUNT = 120

  pattr_initialize [:account!, :currency!, :success_url!, :cancel_url!]

  def perform
    reseller = account.parent
    raise Error, 'Account must have a reseller parent to subscribe to a marketplace plan' if reseller.blank?

    connected_account = reseller.connected_account
    if connected_account.blank? || !connected_account.charges_enabled?
      raise Error, 'Reseller has not completed payment onboarding yet'
    end
    raise Error, 'Reseller is not onboarded on Razorpay' unless connected_account.payment_provider == 'razorpay'

    plan_price = reseller.marketplace_plan_prices.active.find_by(currency: currency.downcase)
    raise Error, "No active pricing found for currency: #{currency.upcase}" if plan_price.blank?
    raise Error, 'Marketplace plan is missing a Razorpay Plan ID' if plan_price.razorpay_plan_id.blank?

    subscription = client.create_subscription(
      plan_id: plan_price.razorpay_plan_id,
      total_count: DEFAULT_TOTAL_COUNT,
      quantity: 1,
      customer_notify: 1,
      notes: {
        relationship_type: 'marketplace',
        client_account_id: account.id.to_s,
        reseller_account_id: reseller.id.to_s,
        connected_account_id: connected_account.id.to_s,
        marketplace_plan_price_id: plan_price.id.to_s,
        platform_fee_amount: plan_price.platform_fee_amount.to_s,
        agency_price: plan_price.agency_price.to_s,
        total_amount: plan_price.total_amount.to_s,
        success_url: success_url,
        cancel_url: cancel_url
      }
    )

    upsert_pending_subscription!(subscription, connected_account, plan_price)

    {
      checkout_url: subscription['short_url'].presence || success_url,
      provider: 'razorpay',
      razorpay_subscription_id: subscription['id']
    }
  end

  private

  def upsert_pending_subscription!(razorpay_subscription, connected_account, plan_price)
    subscription = account.subscription || account.build_subscription
    subscription.assign_attributes(
      payment_provider: 'razorpay',
      relationship_type: 'marketplace',
      connected_account_id: connected_account.id,
      plan_name: 'Marketplace Plan',
      status: razorpay_subscription['status'].presence || 'created',
      razorpay_subscription_id: razorpay_subscription['id'],
      application_fee_amount: plan_price.platform_fee_amount,
      subscribed_quantity: 1
    )
    subscription.save!
  end

  def client
    @client ||= Enterprise::Billing::RazorpayClient.new
  end
end
