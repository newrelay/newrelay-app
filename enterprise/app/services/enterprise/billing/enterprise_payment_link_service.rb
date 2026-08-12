# Creates a hosted checkout URL for a negotiated Enterprise price. Routes to
# Stripe Checkout (USD) or Razorpay Subscriptions (INR) based on the account's
# billing country / locked payment provider.
class Enterprise::Billing::EnterprisePaymentLinkService
  pattr_initialize [:account!, :monthly_price!, :success_url!, :cancel_url!, :provider]

  def perform
    if razorpay?
      return Enterprise::Billing::RazorpayEnterprisePaymentLinkService.new(
        account: account,
        monthly_price: monthly_price,
        success_url: success_url,
        cancel_url: cancel_url
      ).perform
    end

    session = Stripe::Checkout::Session.create(
      mode: 'subscription',
      customer: find_or_create_customer,
      customer_update: { name: 'auto', address: 'auto' },
      billing_address_collection: 'required',
      line_items: [{
        price_data: {
          currency: 'usd',
          product_data: { name: "#{account.name} - Enterprise Plan" },
          unit_amount: (monthly_price.to_f * 100).round,
          recurring: { interval: 'month' }
        },
        quantity: 1
      }],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: session_metadata,
      subscription_data: { metadata: session_metadata }
    )

    { checkout_url: session.url, provider: 'stripe' }
  end

  private

  def razorpay?
    return provider.to_s == 'razorpay' if provider.present?

    locked = account.subscription&.payment_provider
    return locked == 'razorpay' if locked.present?

    Enterprise::Billing::PaymentGatewayRegistry.resolve_provider(
      country: account.custom_attributes['billing_country']
    ) == 'razorpay'
  end

  def session_metadata
    { relationship_type: 'platform', account_id: account.id.to_s, plan_name: 'Enterprise' }
  end

  def find_or_create_customer
    customer_id = account.custom_attributes['stripe_customer_id']
    if customer_id.blank?
      customer = Stripe::Customer.create(
        name: account.name,
        email: account.administrators.first&.email,
        metadata: { account_id: account.id.to_s }
      )
      customer_id = customer.id
      account.update!(custom_attributes: (account.custom_attributes || {}).merge('stripe_customer_id' => customer_id))
    end
    customer_id
  end
end
