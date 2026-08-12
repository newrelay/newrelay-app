class Enterprise::Billing::Tier3CheckoutService
  pattr_initialize [:account!, :currency!, :success_url!, :cancel_url!]

  def perform
    reseller = account.parent
    raise 'Account must have a reseller parent to subscribe to a marketplace plan' if reseller.blank?

    connected_account = reseller.connected_account
    if connected_account.blank? || !connected_account.charges_enabled?
      raise 'Reseller has not completed payment onboarding yet'
    end

    if connected_account.payment_provider == 'razorpay'
      return Enterprise::Billing::RazorpayMarketplaceCheckoutService.new(
        account: account,
        currency: currency,
        success_url: success_url,
        cancel_url: cancel_url
      ).perform
    end

    plan_price = reseller.marketplace_plan_prices.active.find_by(currency: currency.downcase)
    raise "No active pricing found for currency: #{currency.upcase}" if plan_price.blank?

    customer_id = find_or_create_customer(account)

    session_params = {
      mode: 'subscription',
      customer: customer_id,
      customer_update: { name: 'auto', address: 'auto' },
      billing_address_collection: 'required',
      line_items: [{ price: plan_price.stripe_price_id, quantity: 1 }],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: {
        relationship_type: 'marketplace',
        client_account_id: account.id.to_s,
        reseller_account_id: reseller.id.to_s,
        connected_account_id: connected_account.id.to_s,
        marketplace_plan_price_id: plan_price.id.to_s,
        platform_fee_amount: plan_price.platform_fee_amount.to_s,
        agency_price: plan_price.agency_price.to_s,
        total_amount: plan_price.total_amount.to_s
      }
    }

    # Apply charge routing based on reseller configuration
    case connected_account.charge_routing
    when 'destination'
      # Calculate application fee percent as Stripe doesn't support fixed application_fee_amount for subscriptions
      fee_percent = ((plan_price.platform_fee_amount / plan_price.total_amount) * 100.0).round(4)
      session_params[:subscription_data] = {
        transfer_data: {
          destination: connected_account.stripe_account_id
        },
        application_fee_percent: fee_percent,
        metadata: session_params[:metadata]
      }
    when 'separate_charge_transfer'
      # Charges land on platform account first. Transfers are processed manually upon webhook success.
      session_params[:subscription_data] = {
        metadata: session_params[:metadata]
      }
    else
      raise "Unsupported charge routing: #{connected_account.charge_routing}"
    end

    session = Stripe::Checkout::Session.create(session_params)
    { checkout_url: session.url, provider: 'stripe' }
  end

  private

  def find_or_create_customer(acc)
    customer_id = acc.custom_attributes['stripe_customer_id']
    if customer_id.blank?
      customer = Stripe::Customer.create({
                                           name: acc.name,
                                           email: acc.administrators.first&.email,
                                           metadata: {
                                             account_id: acc.id.to_s
                                           }
                                         })
      customer_id = customer.id
      acc.update!(custom_attributes: (acc.custom_attributes || {}).merge('stripe_customer_id' => customer_id))
    end
    customer_id
  end
end
