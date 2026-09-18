class Enterprise::CloudflareDeletionJob < ApplicationJob
  queue_as :default

  def perform(domain)
    return if domain.blank?

    result = Cloudflare::DeleteCustomHostnameService.new(domain: domain).perform
    if result[:errors].present?
      Rails.logger.error("Cloudflare Delete Error for domain #{domain}: #{result[:errors].join(', ')}")
    else
      Rails.logger.info("Successfully deleted custom hostname #{domain} from Cloudflare")
    end

    delete_resend_sending_domain(domain)
  end

  private

  def delete_resend_sending_domain(domain)
    result = Resend::DeleteSendingDomainService.new(domain: domain).perform
    return if result[:skipped] || result[:errors].blank?

    Rails.logger.error("[resend_domain] delete #{domain}: #{Array(result[:errors]).join(', ')}")
  end
end
