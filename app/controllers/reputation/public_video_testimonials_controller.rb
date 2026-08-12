class Reputation::PublicVideoTestimonialsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  layout false

  def new
    @account = Account.find(params[:account_id])
    # Renders app/views/reputation/public_video_testimonials/new.html.erb
  end

  def create
    @account = Account.find(params[:account_id])
    
    @testimonial = @account.reputation_video_testimonials.new(
      title: params[:title],
      email: params[:email]
    )

    if params[:video].present?
      @testimonial.video.attach(params[:video])
    end

    if @testimonial.save
      if params[:token].present?
        request = @account.reputation_review_requests.find_by(token: params[:token])
        request&.update(status: :completed)
      end
      render json: { success: true, message: 'Video uploaded successfully!' }
    else
      render json: { success: false, errors: @testimonial.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
