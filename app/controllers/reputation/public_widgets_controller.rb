# Public endpoint — no auth required.
# GET /reputation/widget/:token/reviews
# GET /reputation/widget/:token/reviews?rating_min=4
class Reputation::PublicWidgetsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def reviews
    widget = Reputation::Widget.find_by!(token: params[:token])
    return head :not_found unless widget.active?

    reviews = Reputation::Review
              .where(account_id: widget.account_id, status: :replied)
              .where('rating >= ?', widget.min_rating)
              .order(reviewed_at: :desc)
              .limit(20)
              .select(:id, :provider, :rating, :body, :reviewer_name, :reviewed_at)

    render json: { widget: widget.slice(:style, :min_rating, :hide_watermark), reviews: reviews }
  end

  # GET /r/:token  — tracks click and redirects to video testimonial recorder
  def redirect
    request = Reputation::ReviewRequest.find_by!(token: params[:token])
    request.update!(status: :clicked, clicked_at: Time.current) if request.sent? || request.delivered?
    
    redirect_to new_reputation_video_testimonial_path(account_id: request.account_id, token: params[:token])
  end
end
