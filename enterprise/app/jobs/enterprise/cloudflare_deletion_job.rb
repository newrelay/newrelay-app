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
  end
end
