# Public, Google-styled review page for mock mode. A customer submits a rating +
# comment; it is stored as a (google) review on the account so it shows up in the
# dashboard Reviews list, where staff can reply (Mock adapter marks the reply published).
class Reputation::PublicReviewsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  layout false

  def new
    @account = Account.find(params[:account_id])
    @submitted = params[:submitted].present?
    # Renders app/views/reputation/public_reviews/new.html.erb
  end

  def create
    @account = Account.find(params[:account_id])
    integration = google_integration
    integration.reputation_reviews.create!(
      account: @account,
      provider: 'google',
      external_id: "public-#{SecureRandom.hex(8)}",
      reviewer_name: params[:reviewer_name].presence || 'Anonymous',
      rating: params[:rating].to_i.clamp(1, 5),
      body: params[:body].to_s.strip,
      status: :pending,
      reviewed_at: Time.current
    )
    redirect_to new_reputation_review_path(account_id: @account.id, submitted: 1)
  end

  private

  # Public reviews attach to the account's Google integration; create a mock one
  # on first use so submitting works even before any platform is connected.
  def google_integration
    @account.reputation_integrations.find_by(provider: 'google') ||
      @account.reputation_integrations.create!(
        provider: 'google',
        location_id: "public-review-page-#{@account.id}",
        location_name: "#{@account.name} (Public Reviews)",
        status: :active
      )
  end
end
