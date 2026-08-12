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
      Reputation::Review.find_or_initialize_by(
        account_id: integration.account_id,
        provider: integration.provider,
        external_id: attrs[:external_id]
      ).update!(attrs.merge(reputation_integration: integration))
    end
  end

  # ponytail: normalize maps only the fields we store — extend when new fields needed
  def normalize(provider, raw)
    case provider
    when 'google'
      {
        external_id: raw['name'],
        rating: raw['starRating'] == 'FIVE' ? 5 : raw['starRating'].to_s.length, # GBP uses enum
        body: raw['comment'],
        reviewer_name: raw.dig('reviewer', 'displayName'),
        reviewed_at: raw['createTime']
      }
    when 'facebook'
      {
        external_id: raw['open_graph_story']&.dig('id') || raw.object_id.to_s,
        rating: raw['rating'].to_i,
        body: raw['review_text'],
        reviewer_name: raw.dig('reviewer', 'name'),
        reviewed_at: raw['created_time']
      }
    end
  end
end
