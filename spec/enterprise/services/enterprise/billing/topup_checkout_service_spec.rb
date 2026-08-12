require 'rails_helper'

describe Enterprise::Billing::TopupCheckoutService do
  subject(:service) do
    described_class.new(
      account: account,
      success_url: 'https://example.com/success',
      cancel_url: 'https://example.com/cancel'
    )
  end

  let(:account) { create(:account) }
  let(:stripe_customer_id) { 'cus_test123' }
  let(:stripe_session) { Struct.new(:url).new('https://checkout.stripe.com/test') }

  before do
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
             { 'name' => 'Hobby', 'product_id' => ['prod_hobby'], 'price_ids' => ['price_hobby'] },
             { 'name' => 'Business', 'product_id' => ['prod_business'], 'price_ids' => ['price_business'] }
           ])

    account.update!(
      custom_attributes: { plan_name: 'Business', stripe_customer_id: stripe_customer_id },
      limits: { 'captain_responses' => 500 }
    )

    allow(Stripe::Checkout::Session).to receive(:create).and_return(stripe_session)
  end

  describe '#create_checkout_session' do
    it 'returns a Stripe checkout URL for a valid topup' do
      result = service.create_checkout_session(credits: 1000)

      expect(result[:checkout_url]).to eq('https://checkout.stripe.com/test')
      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(
          mode: 'payment',
          customer: stripe_customer_id,
          invoice_creation: hash_including(enabled: true),
          metadata: hash_including(source: 'captain_topup', credits: '1000')
        )
      )
    end

    it 'does not credit the account until Stripe webhook confirms payment' do
      service.create_checkout_session(credits: 1000)

      expect(account.reload.limits['captain_responses']).to eq(500)
    end

    it 'raises error for invalid credits' do
      expect { service.create_checkout_session(credits: 500) }.to raise_error do |error|
        expect(error.class.name).to eq('Enterprise::Billing::TopupCheckoutService::Error')
        expect(error.message).to eq(I18n.t('errors.topup.invalid_option'))
      end
    end

    it 'raises error when account is on free plan' do
      account.update!(custom_attributes: { plan_name: 'Hobby', stripe_customer_id: stripe_customer_id })

      expect { service.create_checkout_session(credits: 1000) }.to raise_error do |error|
        expect(error.class.name).to eq('Enterprise::Billing::TopupCheckoutService::Error')
        expect(error.message).to eq(I18n.t('errors.topup.plan_not_eligible'))
      end
    end

    it 'creates a Stripe customer when the account has none yet' do
      account.update!(custom_attributes: { plan_name: 'Business' })
      customer = Struct.new(:id).new('cus_new')
      allow(Stripe::Customer).to receive(:create).and_return(customer)

      service.create_checkout_session(credits: 1000)

      expect(account.reload.custom_attributes['stripe_customer_id']).to eq('cus_new')
      expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(customer: 'cus_new'))
    end
  end
end
