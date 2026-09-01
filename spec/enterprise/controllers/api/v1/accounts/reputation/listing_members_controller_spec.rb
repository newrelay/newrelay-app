# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reputation listing members', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user) }
  let(:other_agent) { create(:user) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['reputation_manage']) }
  let(:downtown) { account.reputation_listings.create!(name: 'Downtown Cafe') }
  let(:airport) { account.reputation_listings.create!(name: 'Airport Shop') }

  before do
    create(:account_user, user: agent, account: account, role: :agent, custom_role: custom_role)
    create(:account_user, user: other_agent, account: account, role: :agent, custom_role: custom_role)
    downtown.listing_members.create!(account: account, user: agent)
    airport.listing_members.create!(account: account, user: other_agent)
  end

  describe 'GET /api/v1/accounts/:account_id/reputation/listings' do
    it 'returns only listings the member owns' do
      get "/api/v1/accounts/#{account.id}/reputation/listings",
          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      names = response.parsed_body.pluck('name')
      expect(names).to eq(['Downtown Cafe'])
    end

    it 'returns all listings for an administrator' do
      get "/api/v1/accounts/#{account.id}/reputation/listings",
          headers: admin.create_new_auth_token, as: :json

      expect(response.parsed_body.pluck('name')).to contain_exactly('Downtown Cafe', 'Airport Shop')
    end
  end

  describe 'GET /api/v1/accounts/:account_id/reputation/listings/:id' do
    it '404s another member listing' do
      get "/api/v1/accounts/#{account.id}/reputation/listings/#{airport.id}",
          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/reputation/listings/:id/members' do
    it 'lets an admin assign a user' do
      post "/api/v1/accounts/#{account.id}/reputation/listings/#{airport.id}/members",
           params: { user_id: agent.id },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:created)
      expect(airport.members).to include(agent, other_agent)
    end

    it 'forbids a member from assigning others' do
      post "/api/v1/accounts/#{account.id}/reputation/listings/#{downtown.id}/members",
           params: { user_id: other_agent.id },
           headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/reputation/review_requests' do
    it 'returns only requests for listings the member owns' do
      create(:reputation_review_request, account: account, reputation_listing_id: downtown.id)
      hidden = create(:reputation_review_request, account: account, reputation_listing_id: airport.id)

      get "/api/v1/accounts/#{account.id}/reputation/review_requests",
          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.pluck('id')).not_to include(hidden.id)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/reputation/video_testimonials' do
    it 'returns only videos for listings the member owns' do
      visible = account.reputation_video_testimonials.create!(
        title: 'Ours', consented_at: Time.current, reputation_listing_id: downtown.id
      )
      hidden = account.reputation_video_testimonials.create!(
        title: 'Theirs', consented_at: Time.current, reputation_listing_id: airport.id
      )

      get "/api/v1/accounts/#{account.id}/reputation/video_testimonials",
          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      ids = response.parsed_body.pluck('id')
      expect(ids).to include(visible.id)
      expect(ids).not_to include(hidden.id)
    end
  end
end
