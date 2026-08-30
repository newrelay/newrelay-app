# Pulls new reviews from the integration's provider (Google/Facebook) and
# upserts them. Provider HTTP + normalization lives in Reputation::Providers::*.
# Scheduled via TriggerScheduledItemsJob on the `scheduled_jobs` queue.
class Reputation::ReviewSyncJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(integration_id)
    integration = Reputation::Integration.find(integration_id)
    return unless integration.active?

    integration.refresh_token! if integration.provider == 'google'

    adapter = Reputation::Providers.adapter_for(integration)
    upsert_reviews(integration, adapter ? adapter.list_reviews : [])
  end

  private

  def upsert_reviews(integration, reviews)
    reviews.each do |attrs|
      next if attrs[:external_id].blank?

      Reputation::Review.find_or_initialize_by(
        account_id: integration.account_id,
        provider: integration.provider,
        external_id: attrs[:external_id]
      ).update!(attrs.merge(reputation_integration: integration))
    rescue ActiveRecord::RecordInvalid => e
      # Isolate per-record failures so one malformed review doesn't abort the sync.
      Rails.logger.error "Reputation review sync skipped a record for integration #{integration.id}: #{e.message}"
    end
  end
end
