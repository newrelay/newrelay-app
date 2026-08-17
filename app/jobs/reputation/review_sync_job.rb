# Pulls new reviews from Google Business Profile and Facebook for all active integrations.
# Scheduled via Sidekiq-cron — runs every 30 minutes on the `scheduled_jobs` queue.
class Reputation::ReviewSyncJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(integration_id)
    integration = Reputation::Integration.find(integration_id)
    return unless integration.active?

    integration.refresh_token! if integration.provider == 'google'

    reviews = fetch_reviews(integration)
    upsert_reviews(integration, reviews)
  end

  private

  def fetch_reviews(integration)
    case integration.provider
    when 'google'   then fetch_google_reviews(integration)
    when 'facebook' then fetch_facebook_reviews(integration)
    else []
    end
  end

  def fetch_google_reviews(integration)
    return [] if integration.access_token.blank?

    response = HTTParty.get(
      "https://mybusiness.googleapis.com/v4/#{integration.location_id}/reviews",
      headers: { 'Authorization' => "Bearer #{integration.access_token}" }
    )
    response.parsed_response.fetch('reviews', [])
  end

  def fetch_facebook_reviews(integration)
    return [] if integration.access_token.blank?

    response = HTTParty.get(
      "https://graph.facebook.com/#{integration.location_id}/ratings",
      query: { access_token: integration.access_token, fields: 'reviewer,rating,review_text,created_time' }
    )
    response.parsed_response.fetch('data', [])
  end

  def upsert_reviews(integration, reviews)
    reviews.each do |raw|
      attrs = normalize(integration.provider, raw)
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

  # GBP returns star ratings as an enum string, not a number.
  GBP_STAR_RATINGS = { 'ONE' => 1, 'TWO' => 2, 'THREE' => 3, 'FOUR' => 4, 'FIVE' => 5 }.freeze

  # ponytail: normalize maps only the fields we store — extend when new fields needed
  def normalize(provider, raw)
    case provider
    when 'google'
      {
        external_id: raw['name'],
        rating: GBP_STAR_RATINGS[raw['starRating']] || 0,
        body: raw['comment'],
        reviewer_name: raw.dig('reviewer', 'displayName'),
        reviewed_at: raw['createTime']
      }
    when 'facebook'
      {
        external_id: facebook_external_id(raw),
        rating: raw['rating'].to_i,
        body: raw['review_text'],
        reviewer_name: raw.dig('reviewer', 'name'),
        reviewed_at: raw['created_time']
      }
    end
  end

  # Prefer FB's stable story id; fall back to a content hash so re-syncs stay idempotent
  # instead of creating a fresh row each run (object_id is not stable across processes).
  def facebook_external_id(raw)
    raw['open_graph_story']&.dig('id') ||
      Digest::SHA256.hexdigest([raw.dig('reviewer', 'name'), raw['review_text'], raw['created_time']].join('|'))
  end
end
