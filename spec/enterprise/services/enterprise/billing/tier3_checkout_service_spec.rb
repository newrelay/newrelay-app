require 'rails_helper'

RSpec.describe Enterprise::Billing::Tier3CheckoutService do
  subject(:service) { described_class.new(account: client_account, currency: 'usd', success_url: 'https://a', cancel_url: 'https://b') }

  let(:reseller) { create(:account, is_reseller: true) }
  let(:client_account) { create(:account, parent: reseller) }

  describe '#perform' do
    context 'when the account has no reseller parent' do
      let(:client_account) { create(:account) }

      it 'raises an error' do
        expect { service.perform }.to raise_error(/must have a reseller parent/)
      end
    end

    context 'when the reseller has not completed payment onboarding' do
      it 'raises an error' do
        expect { service.perform }.to raise_error(/has not completed payment onboarding/)
      end
    end

    context 'when the reseller uses Razorpay' do
      before do
        ConnectedAccount.create!(account: reseller, payment_provider: 'razorpay', razorpay_account_id: 'acc_1',
                                 country: 'IN', charge_routing: 'separate_charge_transfer', charges_enabled: true)
      end

      it 'delegates to the Razorpay marketplace checkout service' do
        allow(Enterprise::Billing::RazorpayMarketplaceCheckoutService).to receive(:new).and_call_original
        allow_any_instance_of(Enterprise::Billing::RazorpayMarketplaceCheckoutService) # rubocop:disable RSpec/AnyInstance
          .to receive(:perform).and_return({ checkout_url: 'https://razorpay.example/pay', provider: 'razorpay' })

        result = service.perform

        expect(result).to eq(checkout_url: 'https://razorpay.example/pay', provider: 'razorpay')
        expect(Enterprise::Billing::RazorpayMarketplaceCheckoutService).to have_received(:new).with(
          account: client_account, currency: 'usd', success_url: 'https://a', cancel_url: 'https://b'
        )
      end
    end

    context 'when the reseller uses Stripe with no active plan price for the currency' do
      before do
        ConnectedAccount.create!(account: reseller, payment_provider: 'stripe', stripe_account_id: 'acct_1',
                                 country: 'US', charge_routing: 'destination', charges_enabled: true)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/No active pricing found for currency: USD/)
      end
    end

    context 'when the reseller uses Stripe with destination charge routing' do
      before do
        MarketplacePlanPrice.create!(account: reseller, currency: 'usd', agency_price: 100, stripe_price_id: 'price_mkt_1')
        ConnectedAccount.create!(account: reseller, payment_provider: 'stripe', stripe_account_id: 'acct_1',
                                 country: 'US', charge_routing: 'destination', charges_enabled: true)
      end

      it 'creates a checkout session with a percentage application fee routed to the reseller' do
        session = instance_double(Stripe::Checkout::Session, url: 'https://checkout.stripe.com/mkt_1')
        allow(Stripe::Customer).to receive(:create).and_return(instance_double(Stripe::Customer, id: 'cus_mkt'))
        allow(Stripe::Checkout::Session).to receive(:create).and_return(session)

        result = service.perform

        expect(result).to eq(checkout_url: 'https://checkout.stripe.com/mkt_1', provider: 'stripe')
        expect(Stripe::Checkout::Session).to have_received(:create).with(
          hash_including(
            line_items: [{ price: 'price_mkt_1', quantity: 1 }],
            subscription_data: hash_including(transfer_data: { destination: 'acct_1' })
          )
        )
      end
    end

    context 'when the reseller uses an unsupported charge routing' do
      before { MarketplacePlanPrice.create!(account: reseller, currency: 'usd', agency_price: 100, stripe_price_id: 'price_mkt_1') }

      let(:connected_account) do
        ConnectedAccount.create!(account: reseller, payment_provider: 'stripe', stripe_account_id: 'acct_1',
                                 country: 'US', charge_routing: 'destination', charges_enabled: true)
      end

      it 'raises an error' do
        connected_account.update_column(:charge_routing, 'unsupported')
        allow(Stripe::Customer).to receive(:create).and_return(instance_double(Stripe::Customer, id: 'cus_mkt'))

        expect { service.perform }.to raise_error(/Unsupported charge routing/)
      end
    end
  end
end
