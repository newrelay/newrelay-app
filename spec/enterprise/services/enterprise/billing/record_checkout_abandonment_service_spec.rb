require 'rails_helper'

RSpec.describe Enterprise::Billing::RecordCheckoutAbandonmentService do
  subject(:service) do
    described_class.new(
      account: account,
      user: user,
      return_type: return_type,
      checkout_type: 'plan_checkout',
      checkout_ref: 'ref-1',
      payment_provider: 'stripe'
    )
  end

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:return_type) { 'cancel' }

  before do
    Subscription.create!(
      account: account,
      payment_provider: 'razorpay',
      relationship_type: 'platform',
      status: 'created',
      plan_name: 'Business'
    )
  end

  it 'logs cancel as a failed checkout' do
    expect { service.perform }.to change(BillingActivityLog, :count).by(1)
    expect(BillingActivityLog.last).to have_attributes(
      action: 'plan_checkout',
      status: 'failed',
      error_class: 'checkout_abandoned'
    )
  end

  it 'does not log a successful return as abandonment' do
    service = described_class.new(
      account: account,
      user: user,
      return_type: 'success',
      checkout_type: 'plan_checkout',
      checkout_ref: 'ref-1',
      payment_provider: 'razorpay'
    )

    expect { service.perform }.not_to change(BillingActivityLog, :count)
  end
end
