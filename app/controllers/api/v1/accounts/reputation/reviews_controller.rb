class Api::V1::Accounts::Reputation::ReviewsController < Api::V1::Accounts::BaseController
  before_action :review, only: [:reply, :ai_draft, :ignore]

  # GET /api/v1/accounts/:account_id/reputation/reviews
  def index
    reviews = current_account.reputation_reviews
                             .includes(:reputation_integration, :reputation_review_reply)
                             .order(reviewed_at: :desc)

    reviews = reviews.where(status: params[:status]) if params[:status].present?
    reviews = reviews.where(provider: params[:provider]) if params[:provider].present?

    render json: reviews.limit(50).as_json(
      only: %i[id external_id provider rating body reviewer_name status reviewed_at],
      include: { reputation_review_reply: { only: %i[id body status published_at] } }
    )
  end

  # POST /api/v1/accounts/:account_id/reputation/reviews/:id/reply
  def reply
    reply = review.reputation_review_reply || review.build_reputation_review_reply(account: current_account)
    reply.update!(body: params.require(:body), status: :draft)

    Reputation::ReplyPublisherJob.perform_later(reply.id) if params[:publish]

    render json: reply, status: :ok
  end

  # GET /api/v1/accounts/:account_id/reputation/reviews/:id/ai_draft
  def ai_draft
    draft = Reputation::AiDraftService.new(review: review).generate
    render json: { draft: draft }
  end

  # PATCH /api/v1/accounts/:account_id/reputation/reviews/:id/ignore
  def ignore
    review.ignored!
    head :no_content
  end

  private

  def review
    @review ||= current_account.reputation_reviews.find(params[:id])
  end
end
