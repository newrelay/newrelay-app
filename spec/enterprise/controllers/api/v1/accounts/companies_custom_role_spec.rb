# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Companies API with company_manage', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['company_manage']) }

  before do
    account.enable_features!(:companies)
    create(:account_user, user: agent, account: account, role: :agent, custom_role: custom_role)
  end

  describe 'GET /api/v1/accounts/:account_id/companies' do
    it 'allows company_manage' do
      get "/api/v1/accounts/#{account.id}/companies",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
    end

    it 'denies custom roles without company_manage' do
      other = create(:user)
      role = create(:custom_role, account: account, permissions: ['contact_manage'])
      create(:account_user, user: other, account: account, role: :agent, custom_role: role)

      get "/api/v1/accounts/#{account.id}/companies",
          headers: other.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
