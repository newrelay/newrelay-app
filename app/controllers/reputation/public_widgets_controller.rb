# Public endpoint — no auth required.
# GET /reputation/widget/:token/reviews
# GET /reputation/widget/:token/reviews?rating_min=4
class Reputation::PublicWidgetsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  layout false

  # GET /reputation/widget/:token — the actual embeddable page (iframe src).
  def show
    @widget = Reputation::Widget.find_by!(token: params[:token])
    return head :not_found unless @widget.active?

    @is_video = @widget.config['source'] == 'video_studio'
    @items = @is_video ? video_items : review_items
  end

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
    review_request = Reputation::ReviewRequest.find_by(token: params[:token])
    return render_expired_link unless review_request&.live_for_public_submit?

    review_request.update!(status: :clicked, clicked_at: Time.current) if review_request.sent? || review_request.delivered?

    url = destination_review_url(review_request)
    return redirect_to url, allow_other_host: true if url.present?

    redirect_to new_reputation_video_testimonial_path(account_id: review_request.account_id, token: params[:token])
  end

  private

  def render_expired_link
    render 'reputation/expired', status: :not_found, layout: false
  end

  def review_items
    Reputation::Review
      .where(account_id: @widget.account_id)
      .where.not(status: :ignored)
      .where('rating >= ?', @widget.min_rating)
      .order(reviewed_at: :desc)
      .limit(12)
  end

  def video_items
    Reputation::VideoTestimonial
      .where(account_id: @widget.account_id, status: :published)
      .where('rating >= ?', @widget.min_rating)
      .order(created_at: :desc)
      .limit(12)
  end

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
