# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deals API with crm_manage', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['crm_manage']) }

  before do
    create(:account_user, user: agent, account: account, role: :agent, custom_role: custom_role)
  end

  describe 'GET /api/v1/accounts/:account_id/deals' do
    it 'allows crm_manage' do
      get "/api/v1/accounts/#{account.id}/deals",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
    end

    it 'denies custom roles without crm_manage' do
      other = create(:user)
      role = create(:custom_role, account: account, permissions: ['contact_manage'])
      create(:account_user, user: other, account: account, role: :agent, custom_role: role)

      get "/api/v1/accounts/#{account.id}/deals",
          headers: other.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/pipelines' do
    it 'allows crm_manage' do
      get "/api/v1/accounts/#{account.id}/pipelines",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
    end

    it 'denies custom roles without crm_manage' do
      other = create(:user)
      role = create(:custom_role, account: account, permissions: ['contact_manage'])
      create(:account_user, user: other, account: account, role: :agent, custom_role: role)

      get "/api/v1/accounts/#{account.id}/pipelines",
          headers: other.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
