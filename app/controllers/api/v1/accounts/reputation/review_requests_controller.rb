class Api::V1::Accounts::Reputation::ReviewRequestsController < Api::V1::Accounts::Reputation::BaseController
  # GET /api/v1/accounts/:account_id/reputation/review_requests
  def index
    requests = scoped_review_requests
               .joins(:reputation_template)
               .where(reputation_templates: { template_type: [nil, 'standard'] })
               .includes(:reputation_template, :contact)
               .order(created_at: :desc)
               .limit(50)
    render json: requests.as_json(
      only: %i[id channel status created_at clicked_at completed_at message destinations token scheduled_at],
      include: {
        reputation_template: { only: %i[id name channel] },
        contact: { only: %i[id name phone_number email] }
      }
    )
  end

  # POST /api/v1/accounts/:account_id/reputation/review_requests
  # Accepts selected contacts (contact_ids) and/or raw emails/phones (recipients),
  # an optional scheduled_at ("Send later"), and the delivery channel.
  def create
    channel = resolve_channel
    template_id = params[:template_id].presence || default_template(channel).id
    scheduled_at = params[:scheduled_at].presence

    recipient_contact_ids.each do |cid|
      Reputation::ReviewRequestSendService.new(
        account: current_account,
        template_id: template_id,
        contact_id: cid,
        listing_id: assignable_listing_id
      ).send!(
        scheduled_at: scheduled_at,
        message: params[:message],
        destinations: params[:destinations]
      )
    end
    head :created
  end

  private

  # WhatsApp isn't a backend channel yet — treat it as SMS (phone-based) for now.
  def resolve_channel
    ch = params[:channel].to_s.downcase
    ch = 'sms' if ch == 'whatsapp'
    Reputation::Template.channels.key?(ch) ? ch : 'email'
  end

  # A reusable default template per channel so the picker never needs one selected.
  def default_template(channel)
    current_account.reputation_templates.standard.find_by(channel: channel) ||
      current_account.reputation_templates.create!(
        name: "Default #{channel} review request",
        channel: channel,
        subject: (channel == 'email' ? 'How was your experience?' : nil),
        body: "Hi {{contact.name}}, we'd love your feedback: {{review_link}}"
      )
  end

  # Selected real contacts (numeric ids) + contacts found/created from raw emails/phones.
  def recipient_contact_ids
    ids = Array(params[:contact_ids]).push(params[:contact_id]).map(&:to_s).grep(/\A\d+\z/).map(&:to_i)
    ids &= current_account.contacts.where(id: ids).pluck(:id)
    raw = Array(params[:recipients]) + Array(params[:email])
    (ids + raw.filter_map { |v| find_or_create_contact(v)&.id }).uniq
  end

  def find_or_create_contact(value)
    value = value.to_s.strip
    return if value.blank?

    if value.include?('@')
      current_account.contacts.from_email(value).first ||
        current_account.contacts.create!(name: value.split('@').first, email: value)
    else
      current_account.contacts.find_by(phone_number: value) ||
        current_account.contacts.create!(name: value, phone_number: value)
    end
  end
end
