module EmailAddressParseable
  extend ActiveSupport::Concern

  NOREPLY_LOCAL_PART = /\A(?:no-?reply|donotreply)\z/i

  private

  def parse_email(email_string)
    Mail::Address.new(email_string).address.presence || default_sender_email_address
  rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
    default_sender_email_address
  end

  def default_sender_email_address
    Mail::Address.new(ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')).address
  end

  def replyable_sender_email(email_string)
    email = parse_email(email_string)
    local, domain = email.to_s.split('@', 2)
    return email if domain.blank? || !local.match?(NOREPLY_LOCAL_PART)

    "mail@#{domain}"
  end

  def email_domain_from(email_string)
    parse_email(email_string).to_s.split('@', 2).last.presence
  end

  def noreply_email?(email_string)
    local = parse_email(email_string).to_s.split('@', 2).first
    local.to_s.match?(NOREPLY_LOCAL_PART)
  end
end
