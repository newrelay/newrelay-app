require 'rails_helper'

RSpec.describe Enterprise::Billing::SyncPaymentTransactionsService do
  subject(:service) { described_class.new(account: account) }

  let(:account) { create(:account) }

  def build_invoice(overrides = {})
    Stripe::Util.convert_to_stripe_object({
      id: 'in_1', customer: 'cus_1', amount_paid: 5_000, amount_due: 5_000, currency: 'usd',
      status: 'paid', attempted: true, billing_reason: 'subscription_cycle', description: nil, charge: nil,
      hosted_invoice_url: nil, invoice_pdf: nil,
      lines: { data: [{ description: 'Business plan' }] }, status_transitions: { paid_at: 1_700_000_000 }, created: 1_690_000_000
    }.merge(overrides), {})
  end

  def stub_invoice_list(invoices, **list_args)
    list = invoices.dup
    list.define_singleton_method(:auto_paging_each) { |&block| each(&block) }
    allow(Stripe::Invoice).to receive(:list).with(hash_including(list_args)).and_return(list)
  end

  describe '#perform' do
    context 'when the account has a Stripe customer id' do
      before { account.update!(custom_attributes: { 'stripe_customer_id' => 'cus_1' }) }

      it 'imports paid invoices as succeeded and attempted-open invoices as failed' do
        invoices = [
          build_invoice(id: 'in_paid'),
          build_invoice(id: 'in_failed', status: 'open', attempted: true),
          build_invoice(id: 'in_pending', status: 'open', attempted: false)
        ]
        stub_invoice_list(invoices, customer: 'cus_1')

        imported = service.perform

        expect(imported).to eq(2)
        expect(PaymentTransaction.find_by(stripe_invoice_id: 'in_paid').status).to eq('succeeded')
        expect(PaymentTransaction.find_by(stripe_invoice_id: 'in_failed').status).to eq('failed')
        expect(PaymentTransaction.find_by(stripe_invoice_id: 'in_pending')).to be_nil
      end

      it 'does not create duplicate transactions when run twice for the same invoice' do
        stub_invoice_list([build_invoice(id: 'in_paid')], customer: 'cus_1')

        service.perform
        expect { service.perform }.not_to change(PaymentTransaction, :count)
      end
    end

    context 'when the account has no Stripe customer id' do
      it 'falls back to matching invoices by account metadata' do
        matching_invoice = build_invoice(id: 'in_meta', metadata: { 'account_id' => account.id.to_s })
        stub_invoice_list([matching_invoice], limit: 100)

        imported = service.perform

        expect(imported).to eq(1)
        expect(PaymentTransaction.find_by(stripe_invoice_id: 'in_meta')).to be_present
      end
    end
  end

  describe '.backfill_all!' do
    it 'imports every resolvable invoice and stamps the customer id back onto the account' do
      invoice = build_invoice(id: 'in_backfill', metadata: { 'account_id' => account.id.to_s })
      stub_invoice_list([invoice], limit: 100)

      imported = described_class.backfill_all!

      expect(imported).to eq(1)
      expect(PaymentTransaction.find_by(stripe_invoice_id: 'in_backfill')).to be_present
      expect(account.reload.custom_attributes['stripe_customer_id']).to eq('cus_1')
    end

    it 'returns 0 and logs when Stripe raises an error' do
      allow(Stripe::Invoice).to receive(:list).and_raise(Stripe::StripeError.new('boom'))

      expect(described_class.backfill_all!).to eq(0)
    end
  end
end
