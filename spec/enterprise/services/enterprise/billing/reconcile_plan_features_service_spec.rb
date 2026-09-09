require 'rails_helper'

RSpec.describe Enterprise::Billing::ReconcilePlanFeaturesService do
  subject(:service) { described_class.new(account: account) }

  let(:account) { create(:account, custom_attributes: { 'plan_name' => plan_name }) }
  let(:plan_name) { 'Business' }

  describe '#perform' do
    context 'when the plan has no configured feature matrix' do
      let(:plan_name) { 'Marketplace Plan' }

      it 'does not change the account features or limits' do
        account.enable_features('macros')

        expect { service.perform }.not_to(change { account.reload.feature_enabled?('macros') })
      end
    end

    context 'when no plan_name is set on the account' do
      let(:account) { create(:account) }

      before { PlanFeatureLimit.create!(plan_key: 'hobby', feature_key: 'seats', limit_value: 2) }

      it 'reconciles against the Hobby plan by default' do
        service.perform

        expect(account.reload.limits['agents']).to eq(2)
      end
    end

    context 'when the plan enables a feature and sets resource limits' do
      before do
        PlanFeatureLimit.create!(plan_key: 'business', feature_key: 'macros', enabled: true)
        PlanFeatureLimit.create!(plan_key: 'business', feature_key: 'seats', limit_value: 10)
      end

      it 'enables the feature and maps the resource limit onto account.limits' do
        service.perform
        account.reload

        expect(account.feature_enabled?('macros')).to be true
        expect(account.limits['agents']).to eq(10)
      end
    end

    context 'when downgrading from a plan with premium features' do
      let(:plan_name) { 'Hobby' }

      before do
        # 'macros' is a known premium feature (tracked under the enterprise matrix)
        PlanFeatureLimit.create!(plan_key: 'enterprise', feature_key: 'macros', enabled: true)
        PlanFeatureLimit.create!(plan_key: 'hobby', feature_key: 'seats', limit_value: 1)
        account.enable_features('macros')
      end

      it 'disables the premium feature that the new plan does not include' do
        service.perform

        expect(account.reload.feature_enabled?('macros')).to be false
      end
    end

    context 'when a manually managed feature is present' do
      before do
        PlanFeatureLimit.create!(plan_key: 'enterprise', feature_key: 'macros', enabled: true)
        PlanFeatureLimit.create!(plan_key: 'business', feature_key: 'seats', limit_value: 10)
        Internal::Accounts::InternalAttributesService.new(account).manually_managed_features = ['macros']
        account.save!
      end

      it 'keeps the manually managed feature enabled regardless of the plan' do
        service.perform

        expect(account.reload.feature_enabled?('macros')).to be true
      end
    end
  end
end
