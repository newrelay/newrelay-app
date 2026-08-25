# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deals API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'POST /api/v1/accounts/{account.id}/deals' do
    it 'creates a deal' do
      pipeline = Pipelines::EnsureDefaultService.new(account: account).perform.first
      stage = pipeline.pipeline_stages.first

      post "/api/v1/accounts/#{account.id}/deals",
           params: {
             deal: {
               name: 'Website Redesign',
               amount_cents: 24_500_00,
               pipeline_id: pipeline.id,
               pipeline_stage_id: stage.id
             }
           },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['name']).to eq('Website Redesign')
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/deals/:id' do
    it 'moves a deal to another stage' do
      deal = create(:deal, account: account, owner: agent)
      next_stage = deal.pipeline.pipeline_stages.second

      patch "/api/v1/accounts/#{account.id}/deals/#{deal.id}",
            params: { deal: { pipeline_stage_id: next_stage.id } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(deal.reload.pipeline_stage_id).to eq(next_stage.id)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/pipelines' do
    it 'ensures default pipeline exists' do
      get "/api/v1/accounts/#{account.id}/pipelines",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].first['name']).to eq('Sales Pipeline')
    end
  end
end
