require 'rails_helper'

RSpec.describe Enterprise::Billing::RazorpayMarketplaceCheckoutService do
  subject(:service) { described_class.new(account: client_account, currency: 'inr', success_url: 'https://a', cancel_url: 'https://b') }

  let(:reseller) { create(:account, is_reseller: true) }
  let(:client_account) { create(:account, parent: reseller) }
  let(:client) { instance_double(Enterprise::Billing::RazorpayClient) }

  before { allow(Enterprise::Billing::RazorpayClient).to receive(:new).and_return(client) }

  describe '#perform' do
    context 'when the account has no reseller parent' do
      let(:client_account) { create(:account) }

      it 'raises an error' do
        expect { service.perform }.to raise_error(described_class::Error, /must have a reseller parent/)
      end
    end

    context 'when the reseller has not completed payment onboarding' do
      it 'raises an error' do
        expect { service.perform }.to raise_error(described_class::Error, /has not completed payment onboarding/)
      end
    end

    context 'when the reseller is onboarded on Stripe instead of Razorpay' do
      before do
        ConnectedAccount.create!(account: reseller, payment_provider: 'stripe', stripe_account_id: 'acct_1', country: 'US',
                                 charge_routing: 'destination', charges_enabled: true)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(described_class::Error, /not onboarded on Razorpay/)
      end
    end

    context 'when the reseller has no active plan price for the currency' do
      before do
        ConnectedAccount.create!(account: reseller, payment_provider: 'razorpay', razorpay_account_id: 'acc_1', country: 'IN',
                                 charge_routing: 'separate_charge_transfer', charges_enabled: true)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(described_class::Error, /No active pricing found for currency: INR/)
      end
    end

    context 'when the plan price has no Razorpay plan id' do
      before do
        ConnectedAccount.create!(account: reseller, payment_provider: 'razorpay', razorpay_account_id: 'acc_1', country: 'IN',
                                 charge_routing: 'separate_charge_transfer', charges_enabled: true)
        allow(client).to receive(:create_plan).and_return({})
        MarketplacePlanPrice.create!(account: reseller, currency: 'inr', agency_price: 80)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(described_class::Error, /missing a Razorpay Plan ID/)
      end
    end

    context 'when everything is configured' do
      let(:connected_account) do
        ConnectedAccount.create!(account: reseller, payment_provider: 'razorpay', razorpay_account_id: 'acc_1', country: 'IN',
                                 charge_routing: 'separate_charge_transfer', charges_enabled: true)
      end

      before do
        connected_account
        MarketplacePlanPrice.create!(account: reseller, currency: 'inr', agency_price: 80, razorpay_plan_id: 'plan_mkt_1')
      end

      it 'creates the subscription, persists it locally, and returns the checkout url' do
        allow(client).to receive(:create_subscription).and_return({ 'id' => 'sub_mkt_new', 'status' => 'created',
                                                                    'short_url' => 'https://rzp.io/mkt' })

        result = service.perform

        expect(result).to eq(checkout_url: 'https://rzp.io/mkt', provider: 'razorpay', razorpay_subscription_id: 'sub_mkt_new')
        subscription = client_account.reload.subscription
        expect(subscription).to have_attributes(
          payment_provider: 'razorpay', relationship_type: 'marketplace', plan_name: 'Marketplace Plan', status: 'created',
          razorpay_subscription_id: 'sub_mkt_new', connected_account_id: connected_account.id
        )
        expect(client).to have_received(:create_subscription).with(hash_including(plan_id: 'plan_mkt_1'))
      end

      it 'falls back to the success url when Razorpay does not return a checkout url' do
        allow(client).to receive(:create_subscription).and_return({ 'id' => 'sub_mkt_new', 'status' => 'created' })

        result = service.perform

        expect(result[:checkout_url]).to eq('https://a')
      end
    end
  end
end
