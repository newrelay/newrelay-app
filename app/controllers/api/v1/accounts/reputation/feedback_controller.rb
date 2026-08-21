class Api::V1::Accounts::Reputation::FeedbackController < Api::V1::Accounts::BaseController
  # GET /api/v1/accounts/:account_id/reputation/feedback
  def index
    submissions = current_account.reputation_feedback_submissions
                                 .includes(:reputation_review_request)
                                 .order(created_at: :desc)

    submissions = submissions.where(rating: params[:rating]) if params[:rating].present?

    render json: submissions.limit(100).as_json(
      only: %i[id rating body reviewer_name created_at],
      include: { reputation_review_request: { only: %i[id channel status] } }
    )
  end
end
