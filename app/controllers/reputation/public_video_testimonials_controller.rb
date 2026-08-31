class Reputation::PublicVideoTestimonialsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  before_action :require_live_review_request, only: [:new, :create]
  layout false

  def new
    # Renders app/views/reputation/public_video_testimonials/new.html.erb
  end

  # Public branded share page (F2). Only approved/published are reachable; 404 otherwise.
  def show
    @testimonial = Reputation::VideoTestimonial.publicly_visible.find_by!(token: params[:token])
    @account = @testimonial.account
    @testimonial.increment!(:views)
    # Renders app/views/reputation/public_video_testimonials/show.html.erb
  end

  def create
    @testimonial = build_testimonial

    if @testimonial.save
      @review_request.update(status: :completed, completed_at: Time.current)
      render json: { success: true, message: 'Video uploaded successfully!' }
    else
      render json: { success: false, errors: @testimonial.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def require_live_review_request
    @review_request = Reputation::ReviewRequest.find_by(token: params[:token])
    return head :not_found unless @review_request&.live_for_public_submit?

    @account = @review_request.account
  end

  def build_testimonial
    testimonial = @account.reputation_video_testimonials.new(testimonial_attributes)
    testimonial.video.attach(params[:video]) if params[:video].present?
    # Client-captured poster frame (canvas → blob); optional.
    testimonial.thumbnail.attach(params[:thumbnail]) if params[:thumbnail].present?
    testimonial
  end

  def testimonial_attributes
    {
      title: params[:title],
      email: params[:email],
      customer_name: params[:customer_name].presence || params[:title],
      rating: params[:rating],
      # Duration is captured client-side (no server ffmpeg dependency).
      duration_seconds: params[:duration_seconds],
      # Consent is the hard gate — only stamp it when the checkbox was ticked;
      # a blank consented_at fails model validation and returns 422.
      consented_at: (Time.current if ActiveModel::Type::Boolean.new.cast(params[:consent])),
      contact: @review_request.contact || find_or_create_contact,
      reputation_review_request: @review_request
    }
  end

  def find_or_create_contact
    return nil if params[:email].blank?

    @account.contacts.from_email(params[:email]) ||
      @account.contacts.create!(name: params[:customer_name].presence || params[:email].split('@').first, email: params[:email])
  end
end
