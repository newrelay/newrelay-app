# Public endpoint — no auth required.
# GET /reputation/widget/:token/reviews
# GET /reputation/widget/:token/reviews?rating_min=4
class Reputation::PublicWidgetsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def reviews
    widget = Reputation::Widget.find_by!(token: params[:token])
    return head :not_found unless widget.active?

    reviews = Reputation::Review
              .where(account_id: widget.account_id)
              .where.not(status: :ignored)
              .where('rating >= ?', widget.min_rating)
              .order(reviewed_at: :desc)
              .limit(20)
              .select(:id, :provider, :rating, :body, :reviewer_name, :reviewed_at)

    render json: { widget: widget.slice(:style, :min_rating, :hide_watermark), reviews: reviews }
  end

  # GET /r/:token  — tracks click, then sends the customer to the chosen review
  # destination (a connected platform's write-review URL) or the testimonial funnel.
  def redirect
    request = Reputation::ReviewRequest.find_by!(token: params[:token])
    request.update!(status: :clicked, clicked_at: Time.current) if request.sent? || request.delivered?

    url = destination_review_url(request)
    return redirect_to url, allow_other_host: true if url.present?

    redirect_to new_reputation_video_testimonial_path(account_id: request.account_id, token: params[:token])
  end

  private

  # Build a real write-review URL for the primary destination if that platform is
  # connected for the account. ponytail: only Google resolves to a real deep link
  # today (via place id); other platforms fall back to the testimonial funnel.
  def destination_review_url(request)
    provider = request.destinations&.first.to_s.downcase.presence
    return if provider.nil?

    integration = Reputation::Integration.find_by(account_id: request.account_id, provider: provider, status: 'active')
    return if integration.nil?

    case provider
    when 'google' then "https://search.google.com/local/writereview?placeid=#{integration.location_id}"
    end
  end
end
