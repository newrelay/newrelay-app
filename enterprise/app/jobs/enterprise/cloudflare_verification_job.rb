class Enterprise::CloudflareVerificationJob < ApplicationJob
  queue_as :default

  def perform(record_type, record_id)
    record = record_type.constantize.find_by(id: record_id)
    return unless record && record.custom_domain.present?

    result = check_hostname_status(record)

    if result[:errors].present?
      Rails.logger.error("Cloudflare Check Error for Account #{record_id}: #{result[:errors].join(', ')}")
      
      create_result = create_hostname(record)
      if create_result && create_result[:errors].present?
        Rails.logger.error("Cloudflare Create Error for Account #{record_id}: #{create_result[:errors].join(', ')}")
      end
    end
  end

  private

  def create_hostname(record)
    Cloudflare::CreateCustomHostnameService.new(record: record).perform
  end

  def check_hostname_status(record)
    Cloudflare::CheckCustomHostnameService.new(record: record).perform
  end
end
