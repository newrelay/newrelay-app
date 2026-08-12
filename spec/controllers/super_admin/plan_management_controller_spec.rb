require 'rails_helper'

RSpec.describe 'Super Admin Plan Management', type: :request do
  let!(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/plan_management' do
    context 'when unauthenticated' do
      it 'redirects to sign in' do
        get '/super_admin/plan_management'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when authenticated as super_admin' do
      it 'renders plan management page with seeded 4-tier plans and limits' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/plan_management'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Plan Management')
        expect(response.body).to include('Hobby')
        expect(response.body).to include('Standard')
        expect(response.body).to include('Business')
        expect(response.body).to include('Enterprise')
        expect(response.body).to include('Seats (team members)')
        expect(response.body).to include('T3 reseller sub-accounts')
      end
    end
  end

  describe 'PATCH /super_admin/plan_management' do
    context 'when authenticated as super_admin' do
      it 'updates prices and resource limits for plans' do
        sign_in(super_admin, scope: :super_admin)

        patch '/super_admin/plan_management', params: {
          plans: {
            'Hobby' => { 'price_per_agent' => '0.00', 'enabled' => '1' },
            'Standard' => { 'price_per_agent' => '15.00', 'enabled' => '1' },
            'Business' => { 'price_per_agent' => '45.00', 'enabled' => '1' },
            'Enterprise' => { 'price_per_agent' => '120.00', 'enabled' => '1' }
          },
          plan_limits: {
            'Hobby' => { 'seats' => '2', 'contacts' => '1000' },
            'Standard' => { 'seats' => '8', 'contacts' => '10000' }
          },
          plan_features: {
            'Hobby' => { 'inbound_emails' => '1', 'white_labeling' => '0' },
            'Standard' => { 'inbound_emails' => '1', 'white_labeling' => '1' }
          }
        }

        expect(response).to redirect_to(super_admin_plan_management_path)
        expect(flash[:notice]).to eq('Plans and feature limits updated successfully.')

        # Verify plans pricing saved in database
        plans = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS').value
        standard_plan = plans.find { |p| p['name'] == 'Standard' }
        business_plan = plans.find { |p| p['name'] == 'Business' }

        expect(standard_plan['price_per_agent']).to eq(15.0)
        expect(business_plan['price_per_agent']).to eq(45.0)

        # Verify plan features & limits saved in database
        expect(PlanFeatureLimit.find_by(plan_key: 'hobby', feature_key: 'seats').limit_value).to eq(2)
        expect(PlanFeatureLimit.find_by(plan_key: 'hobby', feature_key: 'contacts').limit_value).to eq(1000)
        expect(PlanFeatureLimit.find_by(plan_key: 'standard', feature_key: 'seats').limit_value).to eq(8)

        expect(PlanFeatureLimit.find_by(plan_key: 'hobby', feature_key: 'inbound_emails').enabled).to be(true)
        expect(PlanFeatureLimit.find_by(plan_key: 'hobby', feature_key: 'white_labeling').enabled).to be(false)
        expect(PlanFeatureLimit.find_by(plan_key: 'standard', feature_key: 'white_labeling').enabled).to be(true)
      end
    end
  end
end
