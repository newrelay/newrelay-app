class Resend::ProcessReceivedEmailJob < ApplicationJob
  queue_as :mailers

  def perform(email_id)
    Resend::ProcessReceivedEmailService.new(email_id: email_id).perform
  rescue Resend::ProcessReceivedEmailService::Error => e
    Rails.logger.error("[resend_inbound] email_id=#{email_id} #{e.message}")
    raise
  end
end
