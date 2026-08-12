module Enterprise::Concerns::Portal
  extend ActiveSupport::Concern

  included do
    after_save :enqueue_cloudflare_verification, if: :saved_change_to_custom_domain?
  end

  def enqueue_cloudflare_verification
    if saved_change_to_custom_domain? && custom_domain_before_last_save.present? && ChatwootApp.chatwoot_cloud?
      Enterprise::CloudflareDeletionJob.perform_later(custom_domain_before_last_save)
    end

    return if custom_domain.blank?
    return unless ChatwootApp.chatwoot_cloud?

    Enterprise::CloudflareVerificationJob.perform_later('Portal', id)
  end
end
