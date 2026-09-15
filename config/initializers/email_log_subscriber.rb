ActiveSupport::Notifications.subscribe('deliver.action_mailer') do |*, payload|
  next unless payload[:perform_deliveries]

  parsed_mail = Mail.new(payload[:mail])

  EmailLog.create!(
    mailer_class: payload[:mailer],
    to: Array(payload[:to]).join(', '),
    from: Array(payload[:from]).join(', '),
    subject: payload[:subject],
    body: parsed_mail.text_part&.decoded || parsed_mail.html_part&.decoded || parsed_mail.body&.decoded
  )
rescue StandardError => e
  Rails.logger.error("EmailLog: failed to record email - #{e.class}: #{e.message}")
end
