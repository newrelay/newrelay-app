require 'rails_helper'

RSpec.describe Enterprise::Billing::HandleRazorpayEventService do
  subject(:service) { described_class.new }

  let(:account) { create(:account) }

  def subscription_event(event_name, sub_overrides = {})
    {
      'event' => event_name,
      'payload' => {
        'subscription' => {
          'entity' => {
            'id' => 'sub_raz_1',
            'customer_id' => 'cust_raz_1',
            'quantity' => 1,
            'current_start' => 1_000,
            'current_end' => 2_000,
            'status' => 'active',
            'notes' => { 'account_id' => account.id.to_s, 'plan_name' => 'Business' }
          }.merge(sub_overrides)
        }
      }
    }
  end

  describe '#perform' do
    context 'when the same event is processed more than once' do
      it 'processes the same event payload only once' do
        event = subscription_event('subscription.activated')

        expect { service.perform(event: event) }.to change(Subscription, :count).by(1)
        expect { service.perform(event: event) }.not_to change(Subscription, :count)

        expect(ProcessedWebhookEvent.count).to eq(1)
      end

      it 'swallows a race-condition duplicate insert' do
        event = subscription_event('subscription.activated')
        allow(ProcessedWebhookEvent).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)

        expect { service.perform(event: event) }.not_to raise_error
      end

      it 'does not record a dedup entry when the event has no id' do
        event = subscription_event('subscription.activated').except('id')

        expect { service.perform(event: event) }.to change(ProcessedWebhookEvent, :count).by(1)
      end
    end

    context 'when event type is unrecognised' do
      it 'does not raise and still records the webhook event' do
        event = subscription_event('subscription.updated')

        expect { service.perform(event: event) }.to change(ProcessedWebhookEvent, :count).by(1)
        expect(Subscription.count).to eq(0)
      end
    end

    context 'when subscription.activated or subscription.charged fires for a platform subscription' do
      it 'creates the subscription and updates the account' do
        event = subscription_event('subscription.activated')

        service.perform(event: event)

        subscription = account.reload.subscription
        expect(subscription).to have_attributes(
          payment_provider: 'razorpay',
          relationship_type: 'platform',
          plan_name: 'Business',
          status: 'active',
          razorpay_subscription_id: 'sub_raz_1'
        )
        expect(account.custom_attributes['subscription_status']).to eq('active')
        expect(account.custom_attributes['plan_name']).to eq('Business')
      end

      it 'redeems a coupon only on subscription.activated' do
        coupon = BillingCoupon.create!(name: 'Promo', percent_off: 10)
        event = subscription_event('subscription.activated',
                                   'notes' => { 'account_id' => account.id.to_s, 'plan_name' => 'Business', 'coupon_code' => coupon.code })

        expect { service.perform(event: event) }.to change { coupon.reload.times_redeemed }.by(1)
      end

      it 'does not redeem a coupon on subscription.charged' do
        coupon = BillingCoupon.create!(name: 'Promo', percent_off: 10)
        # first activate so a subscription/plan already exists, then charge (renewal)
        service.perform(event: subscription_event('subscription.activated'))

        event = subscription_event('subscription.charged',
                                   'notes' => { 'account_id' => account.id.to_s, 'plan_name' => 'Business', 'coupon_code' => coupon.code })
        expect { service.perform(event: event) }.not_to(change { coupon.reload.times_redeemed })
      end

      it 'does nothing when the account cannot be resolved from notes' do
        event = subscription_event('subscription.activated', 'notes' => { 'account_id' => '0' })

        expect { service.perform(event: event) }.not_to change(Subscription, :count)
      end
    end

    context 'when subscription.charged fires for a marketplace subscription' do
      let(:connected_account) do
        ConnectedAccount.create!(account: create(:account), payment_provider: 'razorpay', razorpay_account_id: 'acc_route_1',
                                 country: 'IN', charge_routing: 'separate_charge_transfer')
      end
      let(:client_account) { create(:account) }
      let!(:plan_price) do
        allow_any_instance_of(Enterprise::Billing::RazorpayClient) # rubocop:disable RSpec/AnyInstance
          .to receive(:create_plan).and_return({ 'id' => 'plan_raz_1' })
        MarketplacePlanPrice.create!(account: connected_account.account, currency: 'inr', agency_price: 80)
      end

      def marketplace_event_notes
        {
          'relationship_type' => 'marketplace',
          'client_account_id' => client_account.id.to_s,
          'marketplace_plan_price_id' => plan_price.id.to_s,
          'connected_account_id' => connected_account.id.to_s,
          'agency_price' => plan_price.agency_price.to_s
        }
      end

      def marketplace_event(event_name)
        {
          'event' => event_name,
          'payload' => {
            'subscription' => {
              'entity' => { 'id' => 'sub_mkt_1', 'quantity' => 1, 'current_start' => 1_000, 'current_end' => 2_000,
                            'notes' => marketplace_event_notes }
            },
            'payment' => { 'entity' => { 'id' => 'pay_1', 'currency' => 'INR' } }
          }
        }
      end

      it 'creates the marketplace subscription and transfers the agency share' do
        expect_any_instance_of(Enterprise::Billing::RazorpayClient) # rubocop:disable RSpec/AnyInstance
          .to receive(:create_transfer).with(hash_including(account: 'acc_route_1', amount: 8000, currency: 'INR'))
                                       .and_return({ 'id' => 'trf_1' })

        service.perform(event: marketplace_event('subscription.charged'))

        subscription = client_account.reload.subscription
        expect(subscription).to have_attributes(relationship_type: 'marketplace', plan_name: 'Marketplace Plan', status: 'active')
      end

      it 'does not attempt a transfer on subscription.activated' do
        expect_any_instance_of(Enterprise::Billing::RazorpayClient).not_to receive(:create_transfer) # rubocop:disable RSpec/AnyInstance

        service.perform(event: marketplace_event('subscription.activated'))
      end

      it 'logs and continues when the transfer API call fails' do
        allow_any_instance_of(Enterprise::Billing::RazorpayClient) # rubocop:disable RSpec/AnyInstance
          .to receive(:create_transfer).and_raise(Enterprise::Billing::RazorpayClient::Error, 'boom')

        expect { service.perform(event: marketplace_event('subscription.charged')) }.not_to raise_error
        expect(client_account.reload.subscription).to be_present
      end
    end

    context 'when subscription.pending or subscription.halted fires' do
      let!(:subscription) do
        Subscription.create!(account: account, payment_provider: 'razorpay', relationship_type: 'platform',
                             razorpay_subscription_id: 'sub_raz_1', status: 'active')
      end

      it 'marks the subscription past_due and starts a grace period' do
        service.perform(event: subscription_event('subscription.pending'))

        subscription.reload
        expect(subscription.status).to eq('past_due')
        expect(subscription.grace_period_ends_at).to be_within(1.minute).of(7.days.from_now)
        expect(account.reload.custom_attributes['subscription_status']).to eq('past_due')
      end

      it 'does not push back an already-running grace period on repeat webhooks' do
        original_grace_period = 2.days.from_now
        subscription.update!(status: 'past_due', grace_period_ends_at: original_grace_period)

        service.perform(event: subscription_event('subscription.halted'))

        expect(subscription.reload.grace_period_ends_at).to be_within(1.second).of(original_grace_period)
      end
    end

    context 'when subscription.cancelled or subscription.completed fires' do
      let!(:subscription) do
        Subscription.create!(account: account, payment_provider: 'razorpay', relationship_type: 'platform',
                             razorpay_subscription_id: 'sub_raz_1', status: 'active')
      end

      it 'cancels the subscription and clears the plan from the account' do
        account.update!(custom_attributes: account.custom_attributes.merge('plan_name' => 'Business'))

        service.perform(event: subscription_event('subscription.cancelled'))

        expect(subscription.reload.status).to eq('canceled')
        expect(account.reload.custom_attributes['subscription_status']).to eq('canceled')
        expect(account.reload.custom_attributes).not_to have_key('plan_name')
      end
    end

    context 'when payment_link.paid or payment.captured fires for a Captain top-up' do
      def topup_event(event_name, credits: 100, source: 'captain_topup')
        notes = { 'source' => source, 'account_id' => account.id.to_s, 'credits' => credits.to_s, 'amount' => '10' }
        {
          'event' => event_name,
          'payload' => {
            'payment_link' => { 'entity' => { 'id' => 'plink_1', 'short_url' => 'https://rzp.io/l/xyz', 'notes' => notes } },
            'payment' => { 'entity' => { 'id' => 'pay_topup_1', 'amount' => 1000, 'currency' => 'INR', 'created_at' => 1_700_000_000 } }
          }
        }
      end

      it 'fulfills credits and records a payment transaction' do
        service.perform(event: topup_event('payment_link.paid'))

        expect(account.reload.limits['captain_responses']).to eq(100)
        txn = PaymentTransaction.find_by(stripe_invoice_id: 'pay_topup_1')
        expect(txn).to have_attributes(status: 'succeeded', billing_reason: 'captain_topup', currency: 'inr')
      end

      it 'does nothing when credits is zero or missing' do
        expect { service.perform(event: topup_event('payment_link.paid', credits: 0)) }.not_to change(PaymentTransaction, :count)
      end

      it 'ignores payment links unrelated to captain topups' do
        expect { service.perform(event: topup_event('payment_link.paid', source: 'other')) }.not_to change(PaymentTransaction, :count)
      end
    end

    context 'when payment.failed fires' do
      it 'records a failed billing activity for the resolved account' do
        event = {
          'event' => 'payment.failed',
          'payload' => {
            'payment' => {
              'entity' => {
                'id' => 'pay_fail_1',
                'error_code' => 'BAD_REQUEST_ERROR',
                'error_description' => 'card declined',
                'notes' => { 'account_id' => account.id.to_s, 'source' => 'captain_topup' }
              }
            }
          }
        }

        expect { service.perform(event: event) }.to change(BillingActivityLog, :count).by(1)

        log = BillingActivityLog.last
        expect(log).to have_attributes(account_id: account.id, action: 'topup_checkout', status: 'failed', error_class: 'BAD_REQUEST_ERROR')
      end
    end
  end
end
