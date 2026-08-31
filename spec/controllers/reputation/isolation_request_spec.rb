require 'rails_helper'

RSpec.describe 'Reputation tenant isolation', type: :request do
  let(:account) { create(:account) }
  let(:other) { create(:account) }
  let(:request_row) { create(:reputation_review_request, account: account, status: :sent) }

  describe 'GET /reputation/video/:account_id/new' do
    it 'returns not found without a token' do
      get new_reputation_video_testimonial_path(account_id: account.id)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for a scheduled or completed token' do
      request_row.update!(status: :scheduled)
      get new_reputation_video_testimonial_path(account_id: account.id, token: request_row.token)
      expect(response).to have_http_status(:not_found)

      request_row.update!(status: :completed, completed_at: Time.current)
      get new_reputation_video_testimonial_path(account_id: account.id, token: request_row.token)
      expect(response).to have_http_status(:not_found)
    end

    it 'opens the recorder for a live token even when the URL account_id is another tenant' do
      get new_reputation_video_testimonial_path(account_id: other.id, token: request_row.token)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /reputation/video/:account_id' do
    it 'does not write without a token' do
      expect do
        post reputation_video_testimonials_path(account_id: account.id), params: { consent: true, title: 'Pat', rating: 5 }
      end.not_to change(Reputation::VideoTestimonial, :count)

      expect(response).to have_http_status(:not_found)
    end

    it 'writes on the token account, not the URL account' do
      expect do
        post reputation_video_testimonials_path(account_id: other.id),
             params: { token: request_row.token, consent: true, title: 'Pat', rating: 5 }
      end.to change { account.reputation_video_testimonials.count }.by(1)

      expect(other.reputation_video_testimonials.count).to eq(0)
      expect(response).to have_http_status(:ok)
      expect(request_row.reload).to be_completed
    end
  end

  describe 'GET /r/:token' do
    it 'returns not found for scheduled or completed tokens' do
      request_row.update!(status: :scheduled)
      get "/r/#{request_row.token}"
      expect(response).to have_http_status(:not_found)

      request_row.update!(status: :completed, completed_at: Time.current)
      get "/r/#{request_row.token}"
      expect(response).to have_http_status(:not_found)
    end

    it 'redirects a live token to the video recorder' do
      get "/r/#{request_row.token}"

      expect(response).to redirect_to(
        new_reputation_video_testimonial_path(account_id: account.id, token: request_row.token)
      )
      expect(request_row.reload).to be_clicked
    end
  end

  describe 'POST /reputation/feedback' do
    it 'returns not found for a spent token' do
      request_row.update!(status: :completed, completed_at: Time.current)

      post '/reputation/feedback', params: { token: request_row.token, rating: 2, body: 'meh' }

      expect(response).to have_http_status(:not_found)
    end

    it 'does not complete the request when validation fails' do
      post '/reputation/feedback', params: { token: request_row.token, rating: 5 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(request_row.reload).to be_sent
      expect(Reputation::FeedbackSubmission.count).to eq(0)
    end

    it 'creates feedback then marks the request completed' do
      post '/reputation/feedback', params: { token: request_row.token, rating: 2, body: 'slow', name: 'Pat' }

      expect(response).to have_http_status(:created)
      expect(request_row.reload).to be_completed
      expect(account.reputation_feedback_submissions.count).to eq(1)
    end
  end

  describe 'unauthenticated sync webhook' do
    it 'is gone' do
      expect do
        get '/api/v1/reputation/sync/1'
      end.not_to have_enqueued_job(Reputation::ReviewSyncJob)
      expect(response).to have_http_status(:not_found)

      expect do
        post '/api/v1/reputation/sync/1'
      end.not_to have_enqueued_job(Reputation::ReviewSyncJob)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'QR public reviews' do
    it 'still writes a review on the account in the URL' do
      expect do
        post reputation_reviews_path(account_id: account.id),
             params: { rating: 5, body: 'Great', reviewer_name: 'Pat' }
      end.to change { account.reputation_reviews.count }.by(1)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'dashboard listings IDOR' do
    let(:agent) { create(:user, account: account, role: :administrator) }

    it 'does not return another account listing' do
      listing = other.reputation_listings.create!(name: 'Other shop')

      get "/api/v1/accounts/#{account.id}/reputation/listings/#{listing.id}",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
