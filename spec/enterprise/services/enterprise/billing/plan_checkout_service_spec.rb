require 'rails_helper'

RSpec.describe Enterprise::Billing::PlanCheckoutService do
  subject(:service) do
    described_class.new(account: account, plan_name: 'Business', success_url: 'https://app.test/success',
                        cancel_url: 'https://app.test/cancel', coupon_code: coupon_code)
  end

  let(:account) { create(:account) }
  let(:coupon_code) { nil }

  before do
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
             { 'name' => 'Business', 'product_id' => ['prod_business'], 'price_ids' => ['price_business'] }
           ])
  end

  describe '#perform' do
    context 'when the plan has no configured price' do
      it 'raises an error instead of creating a checkout session' do
        service = described_class.new(account: account, plan_name: 'Unknown', success_url: 'https://a', cancel_url: 'https://b')
        allow(Stripe::Checkout::Session).to receive(:create)

        expect { service.perform }.to raise_error(described_class::Error, /not available for online purchase/)
        expect(Stripe::Checkout::Session).not_to have_received(:create)
      end
    end

    context 'when the account already has a live Stripe subscription' do
      before do
        Subscription.create!(account: account, payment_provider: 'stripe', relationship_type: 'platform',
                             stripe_subscription_id: 'sub_existing', status: 'past_due')
      end

      it 'returns a billing portal link instead of creating a new checkout session' do
        allow(Stripe::Customer).to receive(:create).and_return(instance_double(Stripe::Customer, id: 'cus_new'))
        allow(Stripe::BillingPortal::Session).to receive(:create).and_return(Struct.new(:url).new('https://billing.stripe.com/portal'))
        allow(Stripe::Checkout::Session).to receive(:create)

        result = service.perform

        expect(result).to eq(checkout_url: 'https://billing.stripe.com/portal')
        expect(Stripe::Checkout::Session).not_to have_received(:create)
      end
    end

    context 'when creating a new checkout session' do
      it 'creates a Stripe customer, persists it, and returns the session url' do
        session = instance_double(Stripe::Checkout::Session, url: 'https://checkout.stripe.com/session_1')
        allow(Stripe::Customer).to receive(:create).and_return(instance_double(Stripe::Customer, id: 'cus_new'))
        allow(Stripe::Checkout::Session).to receive(:create).and_return(session)

        result = service.perform

        expect(result).to eq(checkout_url: 'https://checkout.stripe.com/session_1')
        expect(account.reload.custom_attributes['stripe_customer_id']).to eq('cus_new')
        expect(Stripe::Checkout::Session).to have_received(:create).with(
          hash_including(customer: 'cus_new', line_items: [{ price: 'price_business', quantity: 1 }])
        )
      end

      it 'reuses an existing Stripe customer id without calling Stripe::Customer.create' do
        account.update!(custom_attributes: { 'stripe_customer_id' => 'cus_existing' })
        allow(Stripe::Customer).to receive(:create)
        allow(Stripe::Checkout::Session).to receive(:create).and_return(instance_double(Stripe::Checkout::Session, url: 'https://checkout.stripe.com/x'))

        service.perform

        expect(Stripe::Customer).not_to have_received(:create)
      end
    end

    context 'when a coupon code is supplied' do
      let(:coupon_code) { coupon.code }
      let(:coupon) { BillingCoupon.create!(name: 'Launch discount', percent_off: 15) }

      it 'syncs the coupon to Stripe and attaches it to the checkout session' do
        allow(Stripe::Customer).to receive(:create).and_return(instance_double(Stripe::Customer, id: 'cus_new'))
        allow(Stripe::Coupon).to receive(:create).and_return(instance_double(Stripe::Coupon, id: 'coupon_stripe_1'))
        allow(Stripe::Checkout::Session).to receive(:create).and_return(instance_double(Stripe::Checkout::Session, url: 'https://checkout.stripe.com/y'))

        service.perform

        expect(coupon.reload.stripe_coupon_id).to eq('coupon_stripe_1')
        expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(discounts: [{ coupon: 'coupon_stripe_1' }]))
      end

      context 'when the coupon code does not exist' do
        let(:coupon_code) { 'DOES-NOT-EXIST' }

        it 'raises an error instead of creating a checkout session' do
          allow(Stripe::Checkout::Session).to receive(:create)

          expect { service.perform }.to raise_error(described_class::Error, 'Invalid coupon code')
          expect(Stripe::Checkout::Session).not_to have_received(:create)
        end
      end

      context 'when the coupon does not apply to plan purchases' do
        let(:coupon) { BillingCoupon.create!(name: 'Topup only', percent_off: 15, applies_to: 'topup') }

        it 'raises an error' do
          expect { service.perform }.to raise_error(described_class::Error, /cannot be applied/)
        end
      end
    end
  end
end
