# GMBapi.com adapter — a Google-approved GBP reseller. Same contract as
# Reputation::Providers::Google, so REPUTATION_GOOGLE_PROVIDER=gmbapi swaps the two
# without touching the sync/reply jobs.
#
# API contract (docs.gmbapi.com):
#   Base:    https://api.gmbapi.com/external-api/gmb
#   Reviews: POST /review/location  body: { location_id: }        -> { "data": [ <review>, ... ] }
#   Reply:   POST /review/answer    body: { location_id:, review_name:, comment: }
#   Auth:    Authorization: Bearer <GMBAPI_TOKEN>
# Config: GMBAPI_BASE_URL (defaults to the base above), GMBAPI_TOKEN.
class Reputation::Providers::Gmbapi
  BASE_URL = 'https://api.gmbapi.com/external-api/gmb'.freeze

  def initialize(integration)
    @integration = integration
  end

  # Returns normalized review hashes: { external_id:, rating:, body:, reviewer_name:, reviewed_at: }
  def list_reviews
    response = post('/review/location', location_id: @integration.location_id, per_page: 50)
    raise "GMBapi reviews fetch failed: #{response.body}" unless response.success?

    extract_reviews(response.parsed_response).map { |raw| normalize(raw) }
  end

  def publish_reply(review, body)
    response = post('/review/answer',
                    location_id: @integration.location_id,
                    review_name: review.external_id,
                    comment: body)
    raise "GMBapi reply failed: #{response.body}" unless response.success?
  end

  private

  def post(path, body)
    HTTParty.post("#{base_url}#{path}",
                  headers: { 'Authorization' => "Bearer #{ENV.fetch('GMBAPI_TOKEN', nil)}", 'Content-Type' => 'application/json' },
                  body: body.to_json)
  end

  def base_url
    ENV.fetch('GMBAPI_BASE_URL', BASE_URL)
  end

  # Reviews arrive under "data" (array) or "payload"; tolerate a wrapping hash too.
  def extract_reviews(parsed)
    return [] unless parsed.is_a?(Hash)

    data = parsed['data'] || parsed['payload']
    return data if data.is_a?(Array)

    Array(data.is_a?(Hash) ? (data['reviews'] || data['items']) : nil)
  end

  # GMBapi review object: review_name (Google resource name), rating (int 1-5),
  # comment_native/comment_en (text), reviewerName, created_date (microsecond epoch).
  def normalize(raw)
    {
      external_id: raw['review_name'],
      rating: raw['rating'].to_i,
      body: raw['comment_native'].presence || raw['comment_en'],
      reviewer_name: raw['reviewerName'],
      reviewed_at: parse_time(raw['created_date'])
    }
  end

  def parse_time(value)
    return if value.blank?
    return Time.zone.at(value.to_i / 1_000_000) if value.is_a?(Numeric) || value.to_s.match?(/\A\d+\z/)

    Time.zone.parse(value.to_s)
  rescue StandardError
    nil
  end
end
