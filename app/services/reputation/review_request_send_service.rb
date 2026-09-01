# Renders the template body with contact merge fields and sends via SMS or Email.
# ponytail: uses existing email/SMS Rails infrastructure — no new mailer gem
class Reputation::ReviewRequestSendService
  def initialize(account:, template_id:, contact_id:, listing_id: nil)
    @account  = account
    @template = account.reputation_templates.find(template_id)
    @contact  = account.contacts.find(contact_id)
    @listing_id = listing_id
  end

  # scheduled_at in the future → persist as :scheduled and let the cron dispatch it later.
  # Otherwise create it and hand the actual delivery to a background job.
  def send!(scheduled_at: nil, message: nil, destinations: [])
    scheduled = scheduled_at.present? && scheduled_at.to_time.future?
    request = @account.reputation_review_requests.create!(
      reputation_template: @template,
      contact: @contact,
      reputation_listing_id: @listing_id,
      channel: @template.channel,
      message: message.presence,
      destinations: Array(destinations),
      scheduled_at: (scheduled ? scheduled_at : nil),
      status: (scheduled ? :scheduled : :sent)
    )
    Reputation::SendReviewRequestJob.perform_later(request.id) unless scheduled
    request
  end

  # Called by the job (immediate) and the cron (when a scheduled request comes due).
  def deliver!(request)
    body = render_body(request)
    deliver(body, request)
    request
  end

  private

  # Prefer the composer's message (carries the chosen Tone) over the template body.
  # Support both placeholder styles: template ({{contact.name}}/{{review_link}}) and
  # composer ({{FirstName}}/{{ReviewLink}}/{{BusinessName}}).
  def render_body(request)
    review_link = "#{ENV.fetch('FRONTEND_URL')}/r/#{request.token}"
    (request.message.presence || @template.body)
      .gsub(/\{\{\s*(contact\.name|FirstName)\s*\}\}/, @contact.name.to_s)
      .gsub(/\{\{\s*(review_link|ReviewLink)\s*\}\}/, review_link)
      .gsub(/\{\{\s*BusinessName\s*\}\}/, @account.name.to_s)
  end

  def deliver(body, request)
    return deliver_mock(request) if Reputation::Providers.mock?

    case @template.channel
    when 'sms'   then send_sms(body)
    when 'email' then send_email(body, request)
    end
  end

  # Mock mode: no Twilio/SMTP. The log line is delivery — testers copy /r/:token.
  # Do not mark completed; that happens on the real public submit.
  def deliver_mock(request)
    link = "#{ENV.fetch('FRONTEND_URL', '')}/r/#{request.token}"
    Rails.logger.info("[Reputation::Mock] review request ##{request.id} to " \
                      "#{@contact.email || @contact.phone_number} — link: #{link}")
    request.update!(status: :sent) unless request.sent?
  end

  def send_sms(body)
    # ponytail: reuse the account's configured Twilio SMS channel directly — no new SMS infra.
    channel = @account.twilio_sms.sms.first
    raise 'No Twilio SMS channel configured for this account' if channel.nil?

    channel.send_message(to: @contact.phone_number, body: body)
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
