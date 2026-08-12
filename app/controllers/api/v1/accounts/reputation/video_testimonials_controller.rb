class Api::V1::Accounts::Reputation::VideoTestimonialsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @video_testimonials = Current.account.reputation_video_testimonials.order(created_at: :desc)
    # Renders app/views/api/v1/accounts/reputation/video_testimonials/index.json.jbuilder
  end

  def destroy
    @video_testimonial = Current.account.reputation_video_testimonials.find(params[:id])
    @video_testimonial.destroy!
    head :ok
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
    email = params[:email]
    subject = params[:subject].presence || "We'd love a video testimonial!"
    body = params[:body].presence || "Hi there,\n\nPlease leave us a video testimonial by clicking here: {{video_link}}"
    
    # Find or create a contact to associate the request with
    contact = Current.account.contacts.find_by(email: email)
    if contact.nil?
      contact = Current.account.contacts.create!(
        name: email.split('@').first,
        email: email
      )
    end

    # Get the template if provided, else grab a default video template to satisfy DB constraint
    if params[:template_id].present?
      template = Current.account.reputation_templates.find(params[:template_id])
    else
      template = Current.account.reputation_templates.find_by(template_type: 'video') || Current.account.reputation_templates.first
    end

    # Create the request log
    review_request = Current.account.reputation_review_requests.create!(
      contact: contact,
      reputation_template: template,
      channel: 'email'
    )
    
    # Pass the token so the submitted video can update the request status to completed
    video_link = new_reputation_video_testimonial_url(account_id: Current.account.id, token: review_request.token)
    final_body = body.gsub('{{video_link}}', video_link)

    ReputationRequestMailer.send_request(to: email, subject: subject, body: final_body).deliver_later

    render json: { success: true }
  end

  private

  def check_authorization
    authorize(Current.account, :show?)
  end
end
