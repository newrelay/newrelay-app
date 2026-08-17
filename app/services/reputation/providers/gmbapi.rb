# GMBapi.com adapter — a Google-approved GBP reseller. Same contract as
# Reputation::Providers::Google, so REPUTATION_GOOGLE_PROVIDER=gmbapi swaps the two
# without touching the sync/reply jobs.
#
# NOTE: Endpoint paths and response keys follow GMBapi's Google-native REST shape.
# Confirm them against your GMBapi developer docs (behind account login) — only the
# constants + #normalize / URL builders in THIS file need adjusting; the rest of the
# app is provider-agnostic. Config: GMBAPI_BASE_URL, GMBAPI_TOKEN.
class Reputation::Providers::Gmbapi
  def initialize(integration)
    @integration = integration
  end

  # Returns normalized review hashes: { external_id:, rating:, body:, reviewer_name:, reviewed_at: }
  def list_reviews
    response = HTTParty.get("#{base_url}/locations/#{@integration.location_id}/reviews", headers: auth_headers)
    raise "GMBapi reviews fetch failed: #{response.body}" unless response.success?

    Array(response.parsed_response['reviews']).map { |raw| normalize(raw) }
  end

  def publish_reply(review, body)
    response = HTTParty.put(
      "#{base_url}/locations/#{@integration.location_id}/reviews/#{review.external_id}/reply",
      headers: auth_headers.merge('Content-Type' => 'application/json'),
      body: { comment: body }.to_json
    )
    raise "GMBapi reply failed: #{response.body}" unless response.success?
  end

  private

  def base_url
    ENV.fetch('GMBAPI_BASE_URL', 'https://api.gmbapi.com/v1')
  end

  def auth_headers
    { 'Authorization' => "Bearer #{ENV.fetch('GMBAPI_TOKEN', nil)}" }
  end

  # GMBapi returns Google-native review objects; star rating may be an int or the GBP enum.
  def normalize(raw)
    rating = raw['starRating']
    {
      external_id: raw['reviewId'] || raw['name'],
      rating: rating.is_a?(Integer) ? rating : (Reputation::Providers::Google::STAR_RATINGS[rating] || 0),
      body: raw['comment'],
      reviewer_name: raw.dig('reviewer', 'displayName'),
      reviewed_at: raw['createTime']
    }
  end
end
