# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Campaigns API with marketing_manage', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['marketing_manage']) }
  let(:inbox) { create(:inbox, account: account) }

  before do
    create(:account_user, user: agent, account: account, role: :agent, custom_role: custom_role)
  end

  describe 'GET /api/v1/accounts/:account_id/campaigns' do
    it 'allows marketing_manage' do
      create(:campaign, account: account, inbox: inbox, trigger_rules: { url: 'https://test.com' })

      get "/api/v1/accounts/#{account.id}/campaigns",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
    end

    it 'denies custom roles without marketing_manage' do
      other = create(:user)
      role = create(:custom_role, account: account, permissions: ['contact_manage'])
      create(:account_user, user: other, account: account, role: :agent, custom_role: role)

      get "/api/v1/accounts/#{account.id}/campaigns",
          headers: other.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
