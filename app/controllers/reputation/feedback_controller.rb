# Public — handles ≤3 star private feedback submissions (negative interception)
# POST /reputation/feedback
class Reputation::FeedbackController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    review_request = Reputation::ReviewRequest.find_by(token: params[:token])
    return head :not_found unless review_request&.live_for_public_submit?

    ApplicationRecord.transaction do
      Reputation::FeedbackSubmission.create!(
        account_id: review_request.account_id,
        reputation_review_request: review_request,
        rating: params.require(:rating).to_i,
        body: params[:body],
        reviewer_name: params[:name]
      )
      review_request.update!(status: :completed, completed_at: Time.current)
    end

    head :created
  rescue ActionController::ParameterMissing, ActiveRecord::RecordInvalid
    render json: { error: 'Invalid feedback submission' }, status: :unprocessable_entity
  end
end
