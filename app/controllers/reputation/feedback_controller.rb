# Public — handles ≤3 star private feedback submissions (negative interception)
# POST /reputation/feedback
class Reputation::FeedbackController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    request = Reputation::ReviewRequest.find_by!(token: params.require(:token))
    request.update!(status: :completed, completed_at: Time.current)

    Reputation::FeedbackSubmission.create!(
      account_id: request.account_id,
      reputation_review_request: request,
      rating: params.require(:rating).to_i,
      body: params[:body],
      reviewer_name: params[:name]
    )

    head :created
  end
end
