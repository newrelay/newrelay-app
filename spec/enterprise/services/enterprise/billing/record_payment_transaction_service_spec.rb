require 'rails_helper'

RSpec.describe Enterprise::Billing::RecordPaymentTransactionService do
  subject(:service) { described_class.new(account: account, invoice: invoice, status: status) }

  let(:account) { create(:account) }
  let(:invoice) { build_invoice }
  let(:status) { 'succeeded' }

  def build_invoice(overrides = {})
    Stripe::Util.convert_to_stripe_object({
      id: 'in_1',
      customer: 'cus_1',
      charge: 'ch_1',
      amount_paid: 5_000,
      amount_due: 5_000,
      currency: 'usd',
      billing_reason: 'subscription_cycle',
      hosted_invoice_url: 'https://stripe.example/invoice',
      invoice_pdf: 'https://stripe.example/invoice.pdf',
      description: nil,
      lines: { data: [{ description: 'Business plan' }] },
      status_transitions: { paid_at: 1_700_000_000 },
      created: 1_690_000_000
    }.merge(overrides), {})
  end

  describe '#perform' do
    it 'creates a payment transaction with amounts converted from cents' do
      txn = service.perform

      expect(txn).to have_attributes(
        account_id: account.id,
        stripe_invoice_id: 'in_1',
        stripe_customer_id: 'cus_1',
        stripe_charge_id: 'ch_1',
        amount: 50.0,
        currency: 'usd',
        status: 'succeeded',
        description: 'Business plan',
        billing_reason: 'subscription_cycle'
      )
      expect(txn.paid_at).to eq(Time.zone.at(1_700_000_000))
    end

    context 'when the status is failed' do
      let(:status) { 'failed' }

      it 'records the due amount and leaves paid_at blank' do
        txn = service.perform

        expect(txn.amount).to eq(50.0)
        expect(txn.status).to eq('failed')
        expect(txn.paid_at).to be_nil
      end
    end

    context 'when replaying the same invoice id' do
      it 'updates the existing transaction instead of creating a duplicate' do
        service.perform
        updated_invoice = build_invoice(amount_paid: 7_500)

        expect do
          described_class.new(account: account, invoice: updated_invoice, status: 'succeeded').perform
        end.not_to change(PaymentTransaction, :count)

        expect(PaymentTransaction.find_by(stripe_invoice_id: 'in_1').amount).to eq(75.0)
      end
    end

    context 'when the invoice has no line item description' do
      let(:invoice) { build_invoice(description: nil, lines: { data: [] }, billing_reason: 'manual') }

      it 'falls back to a titleized billing reason' do
        txn = service.perform

        expect(txn.description).to eq('Manual')
      end
    end
  end
end
