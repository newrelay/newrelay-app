require 'rails_helper'

RSpec.describe NumberProvisioning::PollOrderStatusJob do
  let(:account) { create(:account) }
  let(:order) do
    NumberProvisioning::Order.create!(
      account: account, provider_type: 'telnyx', country_code: 'US', phone_number: '+12025550123',
      status: 'order_placed', provider_order_id: 'ord_1', provider_cost_cents: 1000, currency: 'USD'
    )
  end
  let(:provider) { instance_double(NumberProvisioning::TelnyxProvider, release: false) }
  let(:billing) { instance_double(Enterprise::NumberProvisioning::OrderBillingService) }

  before do
    allow(Redis::Alfred).to receive(:set).and_return(true)
    allow(Redis::Alfred).to receive(:delete)
    allow(provider).to receive(:class).and_return(NumberProvisioning::TelnyxProvider)
    allow(NumberProvisioning).to receive(:for).and_return(provider)
    allow(Enterprise::NumberProvisioning::OrderBillingService).to receive(:new).and_return(billing)
    allow(Enterprise::Billing::RecordBillingActivityService).to receive(:new).and_return(instance_double(
                                                                                           Enterprise::Billing::RecordBillingActivityService, perform: true
                                                                                         ))
  end

  it 'polls again while the provider status is still in progress' do
    allow(provider).to receive(:status).and_return({ 'status' => 'order_placed' })

    expect { described_class.perform_now(order.id) }.to have_enqueued_job(described_class)
    expect(order.reload.status).to eq('order_placed')
  end

  it 'stops on an explicit documents status' do
    allow(provider).to receive(:status).and_return({ 'status' => 'requirements_pending' })

    expect { described_class.perform_now(order.id) }.not_to have_enqueued_job(described_class)
    expect(order.reload.status).to eq('requirements_pending')
  end

  it 'does not poll a billing_failed order again' do
    order.update!(status: 'billing_failed', failure_code: 'unknown')
    expect(provider).not_to receive(:status)

    described_class.perform_now(order.id)
  end

  it 'marks unexpected errors failed and does not requeue' do
    allow(provider).to receive(:status).and_raise(RuntimeError, 'boom')

    expect { described_class.perform_now(order.id) }.not_to have_enqueued_job(described_class)
    expect(order.reload.status).to eq('failed')
    expect(order.failure_code).to eq('unknown')
  end

  it 'sets retry 0 when Sidekiq options are available' do
    skip 'sidekiq_options is not defined on this job' unless described_class.respond_to?(:sidekiq_options)

    options = described_class.sidekiq_options
    expect(options['retry'] || options[:retry]).to eq(0)
  end

  it 'marks billing_failed and creates no inbox when the charge raises' do
    allow(provider).to receive(:status).and_return({ 'status' => 'active' })
    allow(billing).to receive(:bill!).and_raise(Enterprise::NumberProvisioning::OrderBillingService::Error.new('currency_mismatch'))

    described_class.perform_now(order.id)

    expect(order.reload.status).to eq('billing_failed')
    expect(order.failure_code).to eq('currency_mismatch')
    expect(order.inbox_id).to be_nil
    expect(Channel::TelnyxSms.count).to eq(0)
  end

  it 'keeps a paid order inbox_pending and does not charge or insert a second channel on retry' do
    allow(provider).to receive(:status).and_return({ 'status' => 'active' })
    allow(billing).to receive(:bill!) { order.update!(billing_reference: 'si_1', margin_cents: 100) }
    raised = false
    allow(Inbox).to receive(:create!).and_wrap_original do |method, *args, **kwargs|
      unless raised
        raised = true
        raise 'inbox down'
      end
      method.call(*args, **kwargs)
    end

    described_class.perform_now(order.id)
    expect(order.reload.status).to eq('inbox_pending')
    expect(Channel::TelnyxSms.count).to eq(1)

    described_class.perform_now(order.id)

    expect(billing).to have_received(:bill!).once
    expect(order.reload.status).to eq('active')
    expect(Channel::TelnyxSms.count).to eq(1)
    expect(order.inbox_id).to be_present
  end
end
