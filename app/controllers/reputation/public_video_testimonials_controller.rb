class Reputation::PublicVideoTestimonialsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  layout false

  def new
    @account = Account.find(params[:account_id])
    # Renders app/views/reputation/public_video_testimonials/new.html.erb
  end

  def create
    @account = Account.find(params[:account_id])
    review_request = params[:token].present? ? @account.reputation_review_requests.find_by(token: params[:token]) : nil
    @testimonial = build_testimonial(review_request)

    if @testimonial.save
      review_request&.update(status: :completed)
      render json: { success: true, message: 'Video uploaded successfully!' }
    else
      render json: { success: false, errors: @testimonial.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def build_testimonial(review_request)
    testimonial = @account.reputation_video_testimonials.new(testimonial_attributes(review_request))
    testimonial.video.attach(params[:video]) if params[:video].present?
    # Client-captured poster frame (canvas → blob); optional.
    testimonial.thumbnail.attach(params[:thumbnail]) if params[:thumbnail].present?
    testimonial
  end

  def testimonial_attributes(review_request)
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
      contact: review_request&.contact || find_or_create_contact,
      reputation_review_request: review_request
    }
  end

  def find_or_create_contact
    return nil if params[:email].blank?

    @account.contacts.from_email(params[:email]) ||
      @account.contacts.create!(name: params[:customer_name].presence || params[:email].split('@').first, email: params[:email])
  end
end
