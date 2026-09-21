class Email::ReplyToBuilder < Email::BaseBuilder
  pattr_initialize [:inbox!, :message!]

  def build
    reply_to = if inbox.email?
                 channel.email
               elsif inbound_reply_domain.present? && (inbound_email_enabled? || noreply_email?(account_support_email))
                 "reply+#{conversation.uuid}@#{inbound_reply_domain}"
               else
                 account_support_email
               end

    sender_name(reply_to)
  end

  private

  def inbound_email_enabled?
    account.feature_enabled?('inbound_emails') && inbound_reply_domain.present?
  end

  def inbound_reply_domain
    account.inbound_email_domain.presence || email_domain_from(account_support_email)
  end
end
