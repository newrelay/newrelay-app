# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Captain assistants API with captain_manage', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['captain_manage']) }

  before do
    create(:account_user, user: agent, account: account, role: :agent, custom_role: custom_role)
  end

  describe 'GET /api/v1/accounts/:account_id/captain/assistants' do
    it 'allows captain_manage' do
      get "/api/v1/accounts/#{account.id}/captain/assistants",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
    end

    it 'denies custom roles without captain_manage' do
      other = create(:user)
      role = create(:custom_role, account: account, permissions: ['contact_manage'])
      create(:account_user, user: other, account: account, role: :agent, custom_role: role)

      get "/api/v1/accounts/#{account.id}/captain/assistants",
          headers: other.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/assistants' do
    let(:valid_attributes) do
      {
        assistant: {
          name: 'New Assistant',
          description: 'Assistant description'
        }
      }
    end

    it 'allows captain_manage to create' do
      post "/api/v1/accounts/#{account.id}/captain/assistants",
           params: valid_attributes,
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
    end
  end
end
