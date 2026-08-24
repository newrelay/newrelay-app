class Api::V1::Accounts::Reputation::VideoTestimonialsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    # eager-load attachments + contact to avoid an N+1 per row (jbuilder reads video_url/thumbnail_url/contact).
    scope = Current.account.reputation_video_testimonials
                   .with_attached_video.with_attached_thumbnail
                   .includes(:contact)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(platform: params[:platform]) if params[:platform].present?
    scope = scope.where(rating: params[:min_rating]..) if params[:min_rating].present?
    @video_testimonials = scope.order(order_clause)
    # Renders app/views/api/v1/accounts/reputation/video_testimonials/index.json.jbuilder
  end

  # Moderation: pending → approved → published / rejected, stamping the transition time.
  def update
    @video_testimonial = Current.account.reputation_video_testimonials.find(params[:id])
    apply_status(params[:status]) if params[:status].present?
    @video_testimonial.assign_attributes(params.permit(:title, :customer_name).to_h.compact)
    @video_testimonial.save!
    render json: { success: true, status: @video_testimonial.status }
  end

  def destroy
    @video_testimonial = Current.account.reputation_video_testimonials.find(params[:id])
    @video_testimonial.destroy!
    head :ok
  end

  # F5: stream the library as CSV (stdlib CSV, no export gem).
  def export
    rows = Current.account.reputation_video_testimonials.includes(:contact).order(created_at: :desc)
    csv = CSV.generate do |out|
      out << %w[id customer_name company email rating status platform duration_seconds views created_at]
      rows.each do |t|
        out << [t.id, t.customer_name, t.company, t.email, t.rating, t.status,
                t.platform, t.duration_seconds, t.views, t.created_at&.iso8601]
      end
    end
    send_data csv, filename: "video-testimonials-#{Date.current}.csv", type: 'text/csv'
  end

  def requests_index
    requests = current_account.reputation_review_requests
                              .joins(:reputation_template)
                              .where(reputation_templates: { template_type: 'video' })
                              .includes(:reputation_template, :contact)
                              .order(created_at: :desc)
                              .limit(50)
    render json: requests.as_json(
      only: %i[id channel status created_at clicked_at completed_at],
      include: {
        reputation_template: { only: %i[id name channel] },
        contact: { only: %i[id name phone_number email] }
      }
    )
  end

  def dispatch_request
    review_request = Current.account.reputation_review_requests.create!(
      contact: find_or_create_request_contact,
      reputation_template: video_template,
      channel: 'email'
    )
    ReputationRequestMailer.send_request(
      to: params[:email],
      subject: params[:subject].presence || "We'd love a video testimonial!",
      body: request_body(review_request)
    ).deliver_later
    render json: { success: true }
  end

  private

  def check_authorization
    authorize(Current.account, :show?)
  end

  def find_or_create_request_contact
    Current.account.contacts.from_email(params[:email]) ||
      Current.account.contacts.create!(name: params[:email].split('@').first, email: params[:email])
  end

  # Prefer the chosen template; else any video template, falling back to the first (DB requires one).
  def video_template
    return Current.account.reputation_templates.find(params[:template_id]) if params[:template_id].present?

    Current.account.reputation_templates.find_by(template_type: 'video') || Current.account.reputation_templates.first
  end

  # Token lets the submitted video mark this request completed; {{video_link}} points at the record page.
  def request_body(review_request)
    default = "Hi there,\n\nPlease leave us a video testimonial by clicking here: {{video_link}}"
    link = new_reputation_video_testimonial_url(account_id: Current.account.id, token: review_request.token)
    (params[:body].presence || default).gsub('{{video_link}}', link)
  end

  # Maps the FE sort chip to a SQL order; defaults to newest first.
  def order_clause
    case params[:sort]
    when 'oldest' then { created_at: :asc }
    when 'rating' then { rating: :desc }
    when 'views'  then { views: :desc }
    else { created_at: :desc }
    end
  end

  # Flip status and stamp the matching transition timestamp.
  def apply_status(new_status)
    return unless Reputation::VideoTestimonial::STATUSES.include?(new_status)

    @video_testimonial.status = new_status
    stamp = { 'approved' => :approved_at, 'published' => :published_at, 'rejected' => :rejected_at }[new_status]
    @video_testimonial[stamp] = Time.current if stamp
  end
end
