# Google Business Profile (v4) adapter. Reads reviews and publishes replies using
# the integration's OAuth access token. Requires Google's GBP API allowlist approval.
class Reputation::Providers::Google
  BASE_URL = 'https://mybusiness.googleapis.com/v4'.freeze
  # GBP returns star ratings as an enum string, not a number.
  STAR_RATINGS = { 'ONE' => 1, 'TWO' => 2, 'THREE' => 3, 'FOUR' => 4, 'FIVE' => 5 }.freeze

  def initialize(integration)
    @integration = integration
  end

  # Returns normalized review hashes: { external_id:, rating:, body:, reviewer_name:, reviewed_at: }
  def list_reviews
    return [] if @integration.access_token.blank?

    response = HTTParty.get("#{BASE_URL}/#{@integration.location_id}/reviews", headers: auth_headers)
    raise "Google reviews fetch failed: #{response.body}" unless response.success?

    Array(response.parsed_response['reviews']).map { |raw| normalize(raw) }
  end

  def publish_reply(review, body)
    response = HTTParty.put(
      "#{BASE_URL}/#{review.external_id}/reply",
      headers: auth_headers.merge('Content-Type' => 'application/json'),
      body: { comment: body }.to_json
    )
    raise "Google reply failed: #{response.body}" unless response.success?
  end

  private

  def auth_headers
    { 'Authorization' => "Bearer #{@integration.access_token}" }
  end

  def normalize(raw)
    {
      external_id: raw['name'],
      rating: STAR_RATINGS[raw['starRating']] || 0,
      body: raw['comment'],
      reviewer_name: raw.dig('reviewer', 'displayName'),
      reviewed_at: raw['createTime']
    }
  end
end
