# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reputation reviews API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user) }

  def headers_for(permissions)
    custom_role = create(:custom_role, account: account, permissions: permissions)
    create(:account_user, user: agent, account: account, role: :agent, custom_role: custom_role)
    agent.create_new_auth_token
  end

  describe 'GET /api/v1/accounts/:account_id/reputation/reviews' do
    it 'allows reputation_manage' do
      get "/api/v1/accounts/#{account.id}/reputation/reviews",
          headers: headers_for(['reputation_manage']),
          as: :json

      expect(response).to have_http_status(:success)
    end

    it 'denies custom roles without reputation_manage' do
      get "/api/v1/accounts/#{account.id}/reputation/reviews",
          headers: headers_for(['contact_manage']),
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'denies agents without reputation_manage' do
      plain_agent = create(:user, account: account, role: :agent)

      get "/api/v1/accounts/#{account.id}/reputation/reviews",
          headers: plain_agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
