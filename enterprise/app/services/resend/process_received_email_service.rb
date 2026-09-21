class Resend::ProcessReceivedEmailService < Resend::BaseService
  class Error < StandardError; end

  pattr_initialize [:email_id!]

  def perform
    if api_key.blank? || email_id.blank?
      Rails.logger.warn('[resend_inbound] skipped: missing API key or email_id')
      return { skipped: true }
    end
    return { skipped: true } if already_processed?

    raw = fetch_raw_source
    raise Error, 'Empty inbound email body' if raw.blank?

    ActionMailbox::InboundEmail.create_and_extract_message_id!(raw)
    claim_event!
    { ok: true }
  rescue ActiveRecord::RecordNotUnique
    claim_event!
    { skipped: true }
  end

  private

  def already_processed?
    ProcessedWebhookEvent.exists?(stripe_event_id: event_key)
  end

  def claim_event!
    ProcessedWebhookEvent.create!(
      stripe_event_id: event_key,
      event_type: 'email.received',
      processed_at: Time.current
    )
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def event_key
    "resend_inbound_#{email_id}"
  end

  def fetch_raw_source
    response = request(:get, "/emails/receiving/#{email_id}")
    raise Error, error_messages(response).join(', ') unless response.success?

    data = response.parsed_response
    download_raw(data.dig('raw', 'download_url')) || build_rfc822(data)
  end

  def download_raw(url)
    return if url.blank?
    return unless allowed_download_host?(url)

    downloaded = HTTParty.get(url, follow_redirects: true, timeout: 30)
    downloaded.body.to_s.b.presence if downloaded.success?
  end

  def allowed_download_host?(url)
    host = URI.parse(url).host.to_s.downcase
    host.end_with?('.resend.com') || host == 'resend.com' || host.end_with?('.cloudfront.net')
  rescue URI::InvalidURIError
    false
  end

  def build_rfc822(data)
    mail = Mail.new
    assign_addresses(mail, data)
    mail.subject = data['subject']
    mail.message_id = data['message_id'].to_s.delete_prefix('<').delete_suffix('>')
    apply_extra_headers(mail, data['headers'])
    assign_body(mail, data)
    mail.to_s
  end

  def assign_addresses(mail, data)
    mail.from = data['from']
    mail.to = (Array(data['to']) + Array(data['received_for'])).uniq
    mail.cc = Array(data['cc'])
    mail.bcc = Array(data['bcc'])
  end

  def assign_body(mail, data)
    if data['text'].present? && data['html'].present?
      mail.text_part = Mail::Part.new(body: data['text'], content_type: 'text/plain')
      mail.html_part = Mail::Part.new(body: data['html'], content_type: 'text/html')
    elsif data['html'].present?
      mail.content_type = 'text/html; charset=UTF-8'
      mail.body = data['html']
    else
      mail.body = data['text'].to_s
    end
  end

  def apply_extra_headers(mail, headers)
    return unless headers.is_a?(Hash)

    headers.each do |key, value|
      next if value.blank? || %w[from to cc bcc subject].include?(key.to_s.downcase)

      mail[key] = value
    end
  end
end
