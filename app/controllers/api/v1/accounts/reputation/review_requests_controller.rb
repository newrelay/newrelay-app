class Api::V1::Accounts::Reputation::ReviewRequestsController < Api::V1::Accounts::BaseController
  # GET /api/v1/accounts/:account_id/reputation/review_requests
  def index
    requests = current_account.reputation_review_requests
                              .joins(:reputation_template)
                              .where(reputation_templates: { template_type: [nil, 'standard'] })
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

  # POST /api/v1/accounts/:account_id/reputation/review_requests
  def create
    contact_id = params[:contact_id]
    
    if contact_id.blank? && params[:email].present?
      email = params[:email].to_s.strip
      contact = current_account.contacts.find_by(email: email)
      if contact.nil?
        contact = current_account.contacts.create!(
          name: email.split('@').first,
          email: email
        )
      end
      contact_id = contact.id
    end

    Reputation::ReviewRequestSendService.new(
      account: current_account,
      template_id: params.require(:template_id),
      contact_id: contact_id
    ).send!
    head :created
  end
end
