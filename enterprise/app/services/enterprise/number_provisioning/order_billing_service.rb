class Enterprise::NumberProvisioning::OrderBillingService
  pattr_initialize [:order!]

  class Error < StandardError
    attr_reader :code

    def initialize(code)
      @code = code
      super(code)
    end
  end

  STRIPE_BILLABLE = %w[active trialing past_due unpaid].freeze
  RAZORPAY_BILLABLE = %w[active authenticated].freeze

  # No account lock around the HTTP call. The subscription item id is saved
  # only after Stripe returns, and the idempotency key is the order id.
  def bill!
    order.reload
    return if order.billing_reference.present?

    raise Error, 'cost_unknown' unless order.provider_cost_cents.to_i.positive?

    subscription = order.account.subscription
    raise Error, 'not_billable' if subscription.blank? || subscription_id_for(subscription).blank?

    remote = fetch_remote(subscription)
    raise Error, 'not_billable' unless billable?(subscription.payment_provider, remote[:status])
    raise Error, 'currency_mismatch' unless currencies_match?(remote[:currency])
    # Razorpay's subscription addon bills once on the next cycle. That is not
    # a monthly line, so Razorpay stays unpaid until a recurring call exists.
    raise Error, 'charge_unavailable' unless subscription.payment_provider == 'stripe'

    item_id = create_stripe_item(subscription_id_for(subscription))
    order.update!(billing_reference: item_id, margin_cents: margin_cents)
  end

  private

  def fetch_remote(subscription)
    case subscription.payment_provider
    when 'stripe'
      remote = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)
      { currency: remote.currency, status: remote.status }
    when 'razorpay'
      client = Enterprise::Billing::RazorpayClient.new
      remote = client.fetch_subscription(subscription.razorpay_subscription_id)
      plan = client.fetch_plan(remote['plan_id']) if remote['plan_id'].present?
      { currency: plan&.dig('item', 'currency') || remote['currency'], status: remote['status'] }
    else
      raise Error, 'not_billable'
    end
  rescue Enterprise::Billing::RazorpayClient::Error, Stripe::StripeError => e
    Rails.logger.info("[NumberProvisioning] subscription fetch failed order_id=#{order.id} error=#{e.class}")
    raise Error, 'not_billable'
  end

  def create_stripe_item(subscription_id)
    key = "numprov-order-#{order.id}"
    product = Stripe::Product.create(
      { name: "Phone number #{order.phone_number}" },
      { idempotency_key: "#{key}-product" }
    )
    price = Stripe::Price.create(
      {
        product: product.id,
        currency: order.currency.to_s.downcase,
        unit_amount: order.provider_cost_cents + margin_cents,
        recurring: { interval: 'month' }
      },
      { idempotency_key: "#{key}-price" }
    )
    item = Stripe::SubscriptionItem.create(
      { subscription: subscription_id, price: price.id, quantity: 1, proration_behavior: 'none' },
      { idempotency_key: key }
    )
    item.id
  rescue Stripe::StripeError => e
    Rails.logger.info("[NumberProvisioning] stripe item failed order_id=#{order.id} error=#{e.class}")
    raise Error, 'unknown'
  end

  def margin_cents
    percent = BigDecimal(NumberProvisioning::ProviderConfig.margin_percent_for(order.provider_type).to_s)
    (BigDecimal(order.provider_cost_cents.to_i) * percent / 100).round.to_i
  end

  def currencies_match?(remote_currency)
    order.currency.present? && remote_currency.to_s.casecmp?(order.currency.to_s)
  end

  def billable?(provider, status)
    list = provider == 'razorpay' ? RAZORPAY_BILLABLE : STRIPE_BILLABLE
    list.include?(status.to_s)
  end

  def subscription_id_for(subscription)
    subscription.payment_provider == 'razorpay' ? subscription.razorpay_subscription_id : subscription.stripe_subscription_id
  end
end
