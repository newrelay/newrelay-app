# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Campaign Analytics API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/campaign_analytics' do
    it 'returns unauthorized for agents' do
      get "/api/v1/accounts/#{account.id}/campaign_analytics",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns analytics payload for administrators' do
      create(:campaign, account: account, inbox: inbox, campaign_status: :active)

      get "/api/v1/accounts/#{account.id}/campaign_analytics",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      payload = response.parsed_body['payload']
      expect(payload['summary']['total_campaigns']).to eq(1)
      expect(payload['campaigns'].length).to eq(1)
    end
  end
end
