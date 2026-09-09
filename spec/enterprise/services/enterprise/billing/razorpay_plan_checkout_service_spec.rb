require 'rails_helper'

RSpec.describe Enterprise::Billing::RazorpayPlanCheckoutService do
  subject(:service) do
    described_class.new(account: account, plan_name: 'Business', success_url: 'https://app.test/success',
                        cancel_url: 'https://app.test/cancel', coupon_code: coupon_code)
  end

  let(:account) { create(:account) }
  let(:coupon_code) { nil }
  let(:client) { instance_double(Enterprise::Billing::RazorpayClient) }

  before do
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
             { 'name' => 'Business', 'razorpay_plan_ids' => ['plan_raz_business'] }
           ])
    allow(Enterprise::Billing::RazorpayClient).to receive(:new).and_return(client)
  end

  describe '#perform' do
    context 'when the account already has an active Razorpay subscription' do
      before do
        Subscription.create!(account: account, payment_provider: 'razorpay', relationship_type: 'platform',
                             razorpay_subscription_id: 'sub_active', status: 'active')
      end

      it 'returns the success url without creating a new subscription' do
        allow(client).to receive(:create_subscription)

        result = service.perform

        expect(result).to eq(checkout_url: 'https://app.test/success', provider: 'razorpay')
        expect(client).not_to have_received(:create_subscription)
      end
    end

    context 'when there is a resumable pending checkout' do
      before do
        Subscription.create!(account: account, payment_provider: 'razorpay', relationship_type: 'platform',
                             razorpay_subscription_id: 'sub_pending', status: 'created', plan_name: 'Business')
        allow(client).to receive(:fetch_subscription).with('sub_pending').and_return({ 'id' => 'sub_pending', 'status' => 'created',
                                                                                       'short_url' => 'https://rzp.io/resume' })
      end

      it 'returns the existing checkout url instead of creating a new subscription' do
        allow(client).to receive(:create_subscription)

        result = service.perform

        expect(result).to eq(checkout_url: 'https://rzp.io/resume', provider: 'razorpay', razorpay_subscription_id: 'sub_pending')
        expect(client).not_to have_received(:create_subscription)
      end
    end

    context 'when the plan has no configured Razorpay plan id' do
      it 'raises an error' do
        service = described_class.new(account: account, plan_name: 'Unknown', success_url: 'https://a', cancel_url: 'https://b')

        expect { service.perform }.to raise_error(described_class::Error, /not available for Razorpay purchase/)
      end
    end

    context 'when creating a fresh checkout' do
      it 'creates the subscription, persists it locally, and returns the checkout url' do
        allow(client).to receive(:create_subscription).and_return({ 'id' => 'sub_new', 'status' => 'created', 'short_url' => 'https://rzp.io/new' })

        result = service.perform

        expect(result).to eq(checkout_url: 'https://rzp.io/new', provider: 'razorpay', razorpay_subscription_id: 'sub_new')
        subscription = account.reload.subscription
        expect(subscription).to have_attributes(payment_provider: 'razorpay', plan_name: 'Business', status: 'created',
                                                razorpay_subscription_id: 'sub_new')
        expect(client).to have_received(:create_subscription).with(hash_including(plan_id: 'plan_raz_business'))
      end

      it 'raises an error when Razorpay does not return a checkout url' do
        allow(client).to receive(:create_subscription).and_return({ 'id' => 'sub_new', 'status' => 'created' })

        expect { service.perform }.to raise_error(described_class::Error, /did not return a checkout URL/)
      end
    end

    context 'when a coupon code is supplied' do
      let(:coupon_code) { coupon.code }
      let(:coupon) { BillingCoupon.create!(name: 'Launch discount', percent_off: 20) }

      it 'creates a discounted Razorpay plan and subscribes to it' do
        allow(client).to receive(:fetch_plan).with('plan_raz_business').and_return({ 'item' => { 'amount' => 10_000, 'currency' => 'INR' },
                                                                                     'period' => 'monthly', 'interval' => 1 })
        allow(client).to receive(:create_plan).and_return({ 'id' => 'plan_raz_discounted' })
        allow(client).to receive(:create_subscription).and_return({ 'id' => 'sub_discounted', 'status' => 'created',
                                                                    'short_url' => 'https://rzp.io/discounted' })

        result = service.perform

        expect(result[:checkout_url]).to eq('https://rzp.io/discounted')
        expect(client).to have_received(:create_plan).with(hash_including(item: hash_including(amount: 8_000)))
        expect(client).to have_received(:create_subscription).with(hash_including(plan_id: 'plan_raz_discounted'))
      end

      context 'when the coupon code is invalid' do
        let(:coupon_code) { 'INVALID' }

        it 'raises an error instead of creating a subscription' do
          allow(client).to receive(:create_subscription)

          expect { service.perform }.to raise_error(described_class::Error, 'Invalid coupon code')
          expect(client).not_to have_received(:create_subscription)
        end
      end
    end
  end
end
