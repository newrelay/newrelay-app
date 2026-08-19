# Facebook Pages ratings adapter. Same contract as the Google adapters.
class Reputation::Providers::Facebook
  def initialize(integration)
    @integration = integration
  end

  # Returns normalized review hashes: { external_id:, rating:, body:, reviewer_name:, reviewed_at: }
  def list_reviews
    return [] if @integration.access_token.blank?

    response = HTTParty.get(
      "https://graph.facebook.com/#{@integration.location_id}/ratings",
      query: { access_token: @integration.access_token,
               fields: 'reviewer,rating,review_text,created_time,open_graph_story' }
    )
    raise "Facebook reviews fetch failed: #{response.body}" unless response.success?

    Array(response.parsed_response['data']).map { |raw| normalize(raw) }
  end

  def publish_reply(review, body)
    response = HTTParty.post(
      "https://graph.facebook.com/#{review.external_id}/comments",
      query: { access_token: @integration.access_token, message: body }
    )
    raise "Facebook reply failed: #{response.body}" unless response.success?
  end

  private

  def normalize(raw)
    {
      external_id: external_id(raw),
      rating: raw['rating'].to_i,
      body: raw['review_text'],
      reviewer_name: raw.dig('reviewer', 'name'),
      reviewed_at: raw['created_time']
    }
  end

  # Prefer FB's stable story id; fall back to a content hash so re-syncs stay idempotent
  # (object_id is not stable across processes).
  def external_id(raw)
    raw['open_graph_story']&.dig('id') ||
      Digest::SHA256.hexdigest([raw.dig('reviewer', 'name'), raw['review_text'], raw['created_time']].join('|'))
  end
end
