require 'rails_helper'

RSpec.describe Enterprise::Billing::RazorpayTopupCheckoutService do
  subject(:service) { described_class.new(account: account, success_url: 'https://a', cancel_url: 'https://b') }

  let(:account) { create(:account, custom_attributes: { 'plan_name' => 'Business' }) }
  let(:client) { instance_double(Enterprise::Billing::RazorpayClient) }

  before { allow(Enterprise::Billing::RazorpayClient).to receive(:new).and_return(client) }

  describe '#create_checkout_session' do
    context 'when credits is not a positive number' do
      it 'raises an error' do
        expect { service.create_checkout_session(credits: 0) }.to raise_error(described_class::Error, I18n.t('errors.topup.invalid_credits'))
      end
    end

    context 'when the account is on a free plan' do
      let(:account) { create(:account, custom_attributes: { 'plan_name' => 'Hacker' }) }

      it 'raises an error' do
        expect { service.create_checkout_session(credits: 1000) }.to raise_error(described_class::Error, I18n.t('errors.topup.plan_not_eligible'))
      end
    end

    context 'when the credits amount does not match a configured topup option' do
      it 'raises an error' do
        expect { service.create_checkout_session(credits: 999) }.to raise_error(described_class::Error, I18n.t('errors.topup.invalid_option'))
      end
    end

    context 'when the request is valid' do
      it 'creates a Razorpay payment link and returns the checkout url' do
        allow(client).to receive(:create_payment_link).and_return({ 'id' => 'plink_1', 'short_url' => 'https://rzp.io/l/topup' })

        result = service.create_checkout_session(credits: 1000)

        expect(result).to eq(checkout_url: 'https://rzp.io/l/topup', provider: 'razorpay', razorpay_payment_link_id: 'plink_1')
        expect(client).to have_received(:create_payment_link).with(
          hash_including(amount: 169_900, currency: 'INR',
                         notes: hash_including(source: 'captain_topup', credits: '1000', account_id: account.id.to_s))
        )
      end
    end
  end
end
