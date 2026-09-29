require 'rails_helper'

RSpec.describe Enterprise::NumberProvisioning::OrderBillingService do
  subject(:service) { described_class.new(order: order) }

  let(:account) { create(:account) }
  let(:order) do
    NumberProvisioning::Order.create!(
      account: account, provider_type: 'telnyx', country_code: 'US', phone_number: '+12025550123',
      status: 'order_placed', provider_order_id: 'ord_1', provider_cost_cents: 1000, currency: 'USD'
    )
  end

  before do
    Subscription.create!(
      account: account, payment_provider: 'stripe', relationship_type: 'platform',
      stripe_subscription_id: 'sub_1', status: 'active'
    )
    allow(NumberProvisioning::ProviderConfig).to receive(:margin_percent_for).and_return('10')
    allow(Stripe::Subscription).to receive(:retrieve).and_return(double(currency: 'usd', status: 'active'))
    allow(Stripe::Product).to receive(:create).and_return(double(id: 'prod_1'))
    allow(Stripe::Price).to receive(:create).and_return(double(id: 'price_1'))
    allow(Stripe::SubscriptionItem).to receive(:create).and_return(double(id: 'si_1'))
  end

  it 'creates one subscription item and reuses it on retry' do
    service.bill!
    service.bill!

    expect(order.reload.billing_reference).to eq('si_1')
    expect(order.margin_cents).to eq(100)
    expect(Stripe::SubscriptionItem).to have_received(:create).once.with(
      hash_including(subscription: 'sub_1', proration_behavior: 'none'),
      hash_including(idempotency_key: "numprov-order-#{order.id}")
    )
  end

  it 'raises currency_mismatch and does not create an item when currencies differ' do
    allow(Stripe::Subscription).to receive(:retrieve).and_return(double(currency: 'eur', status: 'active'))

    expect { service.bill! }.to raise_error(described_class::Error) { |error| expect(error.code).to eq('currency_mismatch') }
    expect(Stripe::SubscriptionItem).not_to have_received(:create)
    expect(Channel::TelnyxSms.count).to eq(0)
  end

  it 'raises charge_unavailable for Razorpay and does not create a Stripe item' do
    account.subscription.update!(payment_provider: 'razorpay', razorpay_subscription_id: 'sub_rzp', stripe_subscription_id: nil)
    client = instance_double(Enterprise::Billing::RazorpayClient)
    allow(Enterprise::Billing::RazorpayClient).to receive(:new).and_return(client)
    allow(client).to receive(:fetch_subscription).and_return({ 'plan_id' => 'plan_1', 'status' => 'active' })
    allow(client).to receive(:fetch_plan).and_return({ 'item' => { 'currency' => 'USD' } })

    expect { service.bill! }.to raise_error(described_class::Error) { |error| expect(error.code).to eq('charge_unavailable') }
    expect(Stripe::SubscriptionItem).not_to have_received(:create)
  end
end
