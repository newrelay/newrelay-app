# US leg: Telnyx has full SIP trunk support and no DLT-style SMS blocker
# for US numbers (unlike its India numbers, which are voice-only).
class NumberProvisioning::TelnyxProvider
  include NumberProvisioning::Provider
  pattr_initialize [:account!]

  BASE_URL = 'https://api.telnyx.com/v2'.freeze

  def search(country_code:, type: nil)
    response = HTTParty.get(
      "#{BASE_URL}/available_phone_numbers",
      headers: auth_headers,
      query: { 'filter[country_code]' => country_code, 'filter[phone_number_type]' => type, 'filter[limit]' => 20 }.compact
    )
    raise "Telnyx search failed: #{response.body}" unless response.success?

    response.parsed_response['data']
  end

  def order(phone_number:)
    response = HTTParty.post(
      "#{BASE_URL}/number_orders",
      headers: auth_headers.merge('Content-Type' => 'application/json'),
      body: { phone_numbers: [{ phone_number: phone_number }] }.to_json
    )
    raise "Telnyx order failed: #{response.body}" unless response.success?

    response.parsed_response['data']
  end

  private

  def auth_headers
    { 'Authorization' => "Bearer #{api_key}" }
  end

  def api_key
    account.hooks.find_by(app_id: 'telnyx', status: 'enabled')&.settings&.dig('api_key') ||
      ENV.fetch('TELNYX_API_KEY', nil)
  end
end
