# Renders the template body with contact merge fields and sends via SMS or Email.
# ponytail: uses existing email/SMS Rails infrastructure — no new mailer gem
class Reputation::ReviewRequestSendService
  def initialize(account:, template_id:, contact_id:)
    @account  = account
    @template = account.reputation_templates.find(template_id)
    @contact  = account.contacts.find(contact_id)
  end

  def send!
    request = @account.reputation_review_requests.create!(
      reputation_template: @template,
      contact: @contact,
      channel: @template.channel
    )

    body = render_body(request)
    deliver(body, request)
    request
  end

  private

  def render_body(request)
    review_link = "#{ENV.fetch('FRONTEND_URL')}/r/#{request.token}"
    @template.body
             .gsub('{{contact.name}}', @contact.name.to_s)
             .gsub('{{review_link}}', review_link)
  end

  def deliver(body, request)
    case @template.channel
    when 'sms'   then send_sms(body)
    when 'email' then send_email(body, request)
    end
  end

  def send_sms(body)
    # ponytail: delegates to existing Twilio SMS infrastructure
    Twilio::SendSmsJob.perform_later(
      to: @contact.phone_number,
      body: body
    )
  end

  def send_email(body, _request)
    # ponytail: plain ActionMailer — no new mailer needed for one template
    ReputationRequestMailer.send_request(
      to: @contact.email,
      subject: @template.subject,
      body: body
    ).deliver_later
  end
end
