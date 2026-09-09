require 'rails_helper'

describe Enterprise::Billing::HandleStripeEventService do
  subject(:stripe_event_service) { described_class }

  let(:event) { double }
  let(:data) { double }
  let(:subscription) { double }
  let!(:account) { create(:account, custom_attributes: { stripe_customer_id: 'cus_123' }) }

  # Feature gating now flows through Enterprise::Billing::ReconcilePlanFeaturesService,
  # which reads its matrix from PlanFeatureLimit (plan_key must be one of
  # PlanFeatureLimit::PLAN_KEYS: hobby/standard/business/enterprise) - there are no
  # hardcoded per-plan feature constants on this class anymore.
  let(:standard_plan_features) { %w[channel_instagram] }
  let(:business_plan_features) { %w[sla custom_roles help_center channel_email] }
  let(:enterprise_plan_features) { %w[audit_logs] }

  before do
    # Create cloud plans configuration
    create(:installation_config, {
             name: 'CHATWOOT_CLOUD_PLANS',
             value: [
               { 'name' => 'Hobby', 'product_id' => ['plan_id_hobby'], 'price_ids' => ['price_hobby'] },
               { 'name' => 'Standard', 'product_id' => ['plan_id_standard'], 'price_ids' => ['price_standard'] },
               { 'name' => 'Business', 'product_id' => ['plan_id_business'], 'price_ids' => ['price_business'] },
               { 'name' => 'Enterprise', 'product_id' => ['plan_id_enterprise'], 'price_ids' => ['price_enterprise'] }
             ]
           })

    create(:installation_config, {
             name: 'CAPTAIN_CLOUD_PLAN_LIMITS',
             value: {
               'hobby' => { 'responses' => 0 },
               'standard' => { 'responses' => 300 },
               'business' => { 'responses' => 500 },
               'enterprise' => { 'responses' => 800 }
             }
           })
    # Setup common subscription mocks
    # Each perform() call needs a distinct event id, otherwise the webhook dedup guard
    # (ProcessedWebhookEvent) would treat a test's second `service.perform(event:)` call
    # (e.g. simulating a plan downgrade after the initial upgrade) as an already-processed
    # duplicate and skip it.
    allow(event).to receive(:data).and_return(data)
    allow(event).to receive(:id) { SecureRandom.uuid }
    allow(subscription).to receive_messages(id: 'sub_123', metadata: {})
    allow(data).to receive(:object).and_return(subscription)
    allow(data).to receive(:previous_attributes).and_return({})
    allow(subscription).to receive(:[]).with('quantity').and_return('10')
    allow(subscription).to receive(:[]).with('status').and_return('active')
    allow(subscription).to receive(:[]).with('current_period_start').and_return(1_686_567_520)
    allow(subscription).to receive(:[]).with('current_period_end').and_return(1_686_567_520)
    allow(subscription).to receive(:customer).and_return('cus_123')
    # process_platform_subscription_updated reads these via method calls (not
    # hash access) to build the Subscription record.
    allow(subscription).to receive(:status).and_return('active')
    allow(subscription).to receive(:cancel_at_period_end).and_return(false)
    allow(event).to receive(:type).and_return('customer.subscription.updated')

    cumulative_by_plan_key = {
      'hobby' => [],
      'standard' => standard_plan_features,
      'business' => standard_plan_features + business_plan_features,
      'enterprise' => standard_plan_features + business_plan_features + enterprise_plan_features
    }
    all_gated_features = standard_plan_features + business_plan_features + enterprise_plan_features
    cumulative_by_plan_key.each do |plan_key, enabled_features|
      all_gated_features.each do |feature|
        PlanFeatureLimit.create!(plan_key: plan_key, feature_key: feature, enabled: enabled_features.include?(feature))
      end
    end
  end

  describe 'subscription update handling' do
    it 'updates account attributes and disables premium features for default plan' do
      # Setup for default (Hobby) plan
      allow(subscription).to receive(:[]).with('plan')
                                         .and_return({ 'id' => 'test', 'product' => 'plan_id_hobby', 'name' => 'Hobby' })

      stripe_event_service.new.perform(event: event)

      # Verify account attributes were updated
      expect(account.reload.custom_attributes).to include(
        'plan_name' => 'Hobby',
        'stripe_product_id' => 'plan_id_hobby',
        'subscription_status' => 'active'
      )

      # Verify premium features are disabled for default plan
      expect(account).not_to be_feature_enabled('channel_email')
      expect(account).not_to be_feature_enabled('help_center')
      expect(account).not_to be_feature_enabled('sla')
      expect(account).not_to be_feature_enabled('custom_roles')
      expect(account).not_to be_feature_enabled('audit_logs')
    end

    it 'resets captain usage on billing period renewal' do
      # Prime the account with some usage
      5.times { account.increment_response_usage }
      expect(account.custom_attributes['captain_responses_usage']).to eq(5)

      # Setup for any plan
      allow(subscription).to receive(:[]).with('plan')
                                         .and_return({ 'id' => 'test', 'product' => 'plan_id_standard', 'name' => 'Standard' })
      allow(subscription).to receive(:[]).with('current_period_start').and_return(1_686_567_520)

      # Simulate billing period renewal with previous_attributes showing old period
      allow(data).to receive(:previous_attributes).and_return({ 'current_period_start' => 1_683_975_520 })

      stripe_event_service.new.perform(event: event)

      # Verify usage was reset
      expect(account.reload.custom_attributes['captain_responses_usage']).to eq(0)
    end
  end

  describe 'subscription quantity update' do
    before do
      allow(subscription).to receive(:[]).with('plan')
                                         .and_return({ 'id' => 'price_standard', 'product' => 'plan_id_standard', 'name' => 'Standard' })
    end

    it 'updates subscribed_quantity' do
      allow(subscription).to receive(:[]).with('quantity').and_return(6)

      stripe_event_service.new.perform(event: event)

      expect(account.reload.custom_attributes['subscribed_quantity']).to eq(6)
    end

    it 'persists quantity even when increment_response_usage runs concurrently' do
      allow(subscription).to receive(:[]).with('quantity').and_return(6)
      account.update!(custom_attributes: account.custom_attributes.merge('captain_responses_usage' => 100))

      # Simulate: webhook updates quantity, then a concurrent increment_response_usage writes usage
      stripe_event_service.new.perform(event: event)
      account.reload

      # Simulate concurrent increment_response_usage (atomic jsonb_set, not full hash overwrite)
      account.increment_response_usage

      # Quantity must survive the concurrent usage update
      expect(account.reload.custom_attributes['subscribed_quantity']).to eq(6)
      expect(account.reload.custom_attributes['captain_responses_usage']).to eq(101)
    end
  end

  describe 'subscription deletion handling' do
    it 'drops the account back to a no-plan state instead of re-subscribing it' do
      account.update!(custom_attributes: account.custom_attributes.merge('plan_name' => 'Standard'))
      allow(event).to receive(:type).and_return('customer.subscription.deleted')

      expect(Enterprise::Billing::CreateStripeCustomerService).not_to receive(:new)

      stripe_event_service.new.perform(event: event)

      account.reload
      expect(account.custom_attributes).not_to have_key('plan_name')
      expect(account.custom_attributes['subscription_status']).to eq('canceled')
    end
  end

  describe 'plan-specific feature management' do
    context 'with default plan (Hobby)' do
      it 'disables all premium features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_hobby', 'name' => 'Hobby' })

        # Enable features first
        all_gated_features = standard_plan_features + business_plan_features + enterprise_plan_features
        account.enable_features(*all_gated_features)
        account.save!

        account.reload
        expect(account).to be_feature_enabled(standard_plan_features.first)

        stripe_event_service.new.perform(event: event)

        account.reload

        all_gated_features.each do |feature|
          expect(account).not_to be_feature_enabled(feature)
        end
      end
    end

    context 'with Standard plan' do
      it 'enables common features but not premium features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_standard', 'name' => 'Standard' })

        stripe_event_service.new.perform(event: event)

        # Verify basic (Standard) features are enabled
        account.reload
        standard_plan_features.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        # But business and enterprise features should be disabled
        business_plan_features.each do |feature|
          expect(account).not_to be_feature_enabled(feature)
        end

        enterprise_plan_features.each do |feature|
          expect(account).not_to be_feature_enabled(feature)
        end
      end
    end

    context 'with Business plan' do
      it 'enables business-specific features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_business', 'name' => 'Business' })

        stripe_event_service.new.perform(event: event)

        account.reload
        standard_plan_features.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        business_plan_features.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        enterprise_plan_features.each do |feature|
          expect(account).not_to be_feature_enabled(feature)
        end
      end
    end

    context 'with Enterprise plan' do
      it 'enables all business and enterprise features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_enterprise', 'name' => 'Enterprise' })

        stripe_event_service.new.perform(event: event)

        account.reload
        standard_plan_features.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        business_plan_features.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        enterprise_plan_features.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end
      end
    end
  end

  describe 'manually managed features' do
    let(:service) { stripe_event_service.new }
    let(:internal_attrs_service) { instance_double(Internal::Accounts::InternalAttributesService) }

    before do
      # Mock the internal attributes service
      allow(Internal::Accounts::InternalAttributesService).to receive(:new).with(account).and_return(internal_attrs_service)
    end

    context 'when downgrading with manually managed features' do
      it 'preserves manually managed features even when downgrading plans' do
        # Setup: account has Enterprise plan with manually managed features
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_enterprise', 'name' => 'Enterprise' })

        # Mock manually managed features
        allow(internal_attrs_service).to receive(:manually_managed_features).and_return(%w[audit_logs custom_roles])

        # First run to apply enterprise plan
        service.perform(event: event)
        account.reload

        # Verify features are enabled
        expect(account).to be_feature_enabled('audit_logs')
        expect(account).to be_feature_enabled('custom_roles')

        # Now downgrade to Hobby plan (which normally wouldn't have these features)
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_hobby', 'name' => 'Hobby' })

        service.perform(event: event)
        account.reload

        # Manually managed features should still be enabled despite plan downgrade
        expect(account).to be_feature_enabled('audit_logs')
        expect(account).to be_feature_enabled('custom_roles')

        # But other premium features should be disabled
        expect(account).not_to be_feature_enabled('channel_instagram')
        expect(account).not_to be_feature_enabled('help_center')
      end
    end
  end

  describe 'downgrade handling' do
    let(:service) { stripe_event_service.new }

    before do
      # Setup internal attributes service mock to return no manually managed features
      internal_attrs_service = instance_double(Internal::Accounts::InternalAttributesService)
      allow(Internal::Accounts::InternalAttributesService).to receive(:new).with(account).and_return(internal_attrs_service)
      allow(internal_attrs_service).to receive(:manually_managed_features).and_return([])
    end

    context 'when downgrading from Enterprise to Business plan' do
      before do
        # Start with Enterprise plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_enterprise', 'name' => 'Enterprise' })
        service.perform(event: event)
        account.reload
      end

      it 'retains business features but disables enterprise features' do
        # Verify enterprise features were enabled
        expect(account).to be_feature_enabled('audit_logs')

        # Downgrade to Business plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_business', 'name' => 'Business' })
        service.perform(event: event)

        account.reload
        expect(account).to be_feature_enabled('sla')
        expect(account).to be_feature_enabled('custom_roles')
        expect(account).not_to be_feature_enabled('audit_logs')
      end
    end

    context 'when downgrading from Business to Standard plan' do
      before do
        # Start with Business plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_business', 'name' => 'Business' })
        service.perform(event: event)
        account.reload
      end

      it 'retains startup features but disables business features' do
        # Verify business features were enabled
        expect(account).to be_feature_enabled('sla')

        # Downgrade to Standard plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_standard', 'name' => 'Standard' })
        service.perform(event: event)

        account.reload
        # Spot check one startup feature
        expect(account).to be_feature_enabled('channel_instagram')
        expect(account).not_to be_feature_enabled('sla')
        expect(account).not_to be_feature_enabled('custom_roles')
      end
    end

    context 'when downgrading from Standard to Hobby plan' do
      before do
        # Start with Standard plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_standard', 'name' => 'Standard' })
        service.perform(event: event)
        account.reload
      end

      it 'disables all premium features' do
        # Verify startup features were enabled
        expect(account).to be_feature_enabled('channel_instagram')

        # Downgrade to Hobby (default) plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_hobby', 'name' => 'Hobby' })
        service.perform(event: event)

        account.reload
        # Spot check that premium features are disabled
        expect(account).not_to be_feature_enabled('channel_instagram')
        expect(account).not_to be_feature_enabled('help_center')
      end
    end
  end
end
