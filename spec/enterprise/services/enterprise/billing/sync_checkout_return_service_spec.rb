require 'rails_helper'

RSpec.describe Enterprise::Billing::SyncCheckoutReturnService do
  subject(:service) do
    described_class.new(
      account: account,
      return_type: return_type,
      checkout_type: checkout_type,
      checkout_session_id: checkout_session_id
    )
  end

  let(:account) { create(:account, custom_attributes: { stripe_customer_id: 'cus_123' }) }
  let(:return_type) { 'success' }
  let(:checkout_type) { 'plan_checkout' }
  let(:checkout_session_id) { nil }

  describe '#perform' do
    it 'is a no-op on cancel' do
      service = described_class.new(
        account: account,
        return_type: 'cancel',
        checkout_type: 'plan_checkout',
        checkout_session_id: 'cs_test_1'
      )
      allow(Stripe::Checkout::Session).to receive(:retrieve)

      expect(service.perform).to be(false)
      expect(Stripe::Checkout::Session).not_to have_received(:retrieve)
    end

    it 'skips Stripe when the account is already unlocked' do
      account.update!(custom_attributes: account.custom_attributes.merge('plan_name' => 'Business'))
      Subscription.create!(account: account, payment_provider: 'stripe', relationship_type: 'platform',
                           status: 'active', stripe_customer_id: 'cus_123')
      allow(Stripe::Checkout::Session).to receive(:retrieve)

      result = described_class.new(
        account: account.reload,
        return_type: 'success',
        checkout_type: 'plan_checkout',
        checkout_session_id: 'cs_test_1'
      ).perform

      expect(result).to be(false)
      expect(Stripe::Checkout::Session).not_to have_received(:retrieve)
    end

    context 'when Stripe returns a paid checkout session' do
      let(:checkout_session_id) { 'cs_test_paid' }
      let(:session) do
        Stripe::Checkout::Session.construct_from(
          id: 'cs_test_paid',
          customer: 'cus_123',
          subscription: 'sub_paid',
          metadata: { 'account_id' => account.id.to_s, 'plan_name' => 'Business' }
        )
      end
      let(:stripe_subscription) do
        Stripe::Subscription.construct_from(
          id: 'sub_paid',
          customer: 'cus_123',
          status: 'active',
          quantity: 1,
          current_period_start: 1_686_567_520,
          current_period_end: 1_689_159_520,
          cancel_at_period_end: false,
          plan: { 'id' => 'price_business', 'product' => 'plan_id_business' },
          metadata: { 'account_id' => account.id.to_s, 'plan_name' => 'Business' }
        )
      end

      before do
        create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
                 { 'name' => 'Business', 'product_id' => ['plan_id_business'], 'price_ids' => ['price_business'] }
               ])
        allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(session)
        allow(Stripe::Subscription).to receive(:retrieve).with('sub_paid').and_return(stripe_subscription)
      end

      it 'applies the Stripe subscription to the account' do
        expect(service.perform).to be(true)

        expect(account.reload.custom_attributes['plan_name']).to eq('Business')
        expect(account.subscription).to have_attributes(status: 'active', stripe_subscription_id: 'sub_paid')
        expect(account.subscription).to be_active
      end

      it 'ignores a session that belongs to another account' do
        foreign = Stripe::Checkout::Session.construct_from(
          id: 'cs_test_paid',
          customer: 'cus_other',
          subscription: 'sub_paid',
          metadata: { 'account_id' => '999999' }
        )
        allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(foreign)
        allow(Stripe::Subscription).to receive(:retrieve)

        expect(service.perform).to be(false)
        expect(Stripe::Subscription).not_to have_received(:retrieve)
        expect(account.reload.subscription).to be_nil
      end
    end

    context 'when a pending Razorpay subscription has been paid' do
      let(:client) { instance_double(Enterprise::Billing::RazorpayClient) }

      before do
        Subscription.create!(
          account: account,
          payment_provider: 'razorpay',
          relationship_type: 'platform',
          status: 'created',
          plan_name: 'Business',
          razorpay_subscription_id: 'sub_raz_1'
        )
        allow(Enterprise::Billing::RazorpayClient).to receive(:new).and_return(client)
        allow(client).to receive(:fetch_subscription).with('sub_raz_1').and_return(
          'id' => 'sub_raz_1',
          'customer_id' => 'cust_raz_1',
          'quantity' => 1,
          'status' => 'active',
          'current_start' => 1_000,
          'current_end' => 2_000,
          'notes' => { 'account_id' => account.id.to_s, 'plan_name' => 'Business' }
        )
      end

      it 'activates the local subscription' do
        expect(service.perform).to be(true)

        expect(account.reload.subscription).to have_attributes(status: 'active', plan_name: 'Business')
        expect(account.custom_attributes['plan_name']).to eq('Business')
      end
    end
  end
end
