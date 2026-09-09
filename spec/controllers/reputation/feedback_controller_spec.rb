require 'rails_helper'

RSpec.describe 'Reputation::FeedbackController', type: :request do
  let(:account) { create(:account) }
  let(:review_request) { create(:reputation_review_request, account: account, status: :sent) }

  describe 'POST /reputation/feedback' do
    it 'returns not found for an unknown token' do
      post '/reputation/feedback', params: { token: 'does-not-exist', rating: 2 }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for a token that has not been sent yet' do
      review_request.update!(status: :scheduled)

      post '/reputation/feedback', params: { token: review_request.token, rating: 2 }

      expect(response).to have_http_status(:not_found)
    end

    %w[sent delivered clicked].each do |live_status|
      it "accepts feedback for a #{live_status} request" do
        review_request.update!(status: live_status)

        post '/reputation/feedback', params: { token: review_request.token, rating: 2, body: 'slow', name: 'Pat' }

        expect(response).to have_http_status(:created)
      end
    end

    it 'creates the submission and completes the request on the happy path' do
      post '/reputation/feedback', params: { token: review_request.token, rating: 1, body: 'terrible service', name: 'Pat' }

      expect(response).to have_http_status(:created)
      submission = account.reputation_feedback_submissions.sole
      expect(submission.rating).to eq(1)
      expect(submission.body).to eq('terrible service')
      expect(submission.reviewer_name).to eq('Pat')
      expect(submission.reputation_review_request).to eq(review_request)
      expect(review_request.reload).to be_completed
      expect(review_request.completed_at).to be_present
    end

    it 'rejects a rating outside the negative-feedback gate (1..3) and does not complete the request' do
      post '/reputation/feedback', params: { token: review_request.token, rating: 5, body: 'loved it' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Reputation::FeedbackSubmission.count).to eq(0)
      expect(review_request.reload).to be_sent
    end

    it 'rejects a missing rating param and does not complete the request' do
      post '/reputation/feedback', params: { token: review_request.token, body: 'no rating' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Reputation::FeedbackSubmission.count).to eq(0)
      expect(review_request.reload).to be_sent
    end

    it 'does not accept a second submission once the request is already completed' do
      review_request.update!(status: :completed, completed_at: Time.current)

      post '/reputation/feedback', params: { token: review_request.token, rating: 2 }

      expect(response).to have_http_status(:not_found)
      expect(Reputation::FeedbackSubmission.count).to eq(0)
    end
  end
end
