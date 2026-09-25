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

  def status(provider_order_id:)
    response = HTTParty.get("#{BASE_URL}/number_orders/#{provider_order_id}", headers: auth_headers)
    raise "Telnyx status check failed: #{response.body}" unless response.success?

    response.parsed_response['data']
  end

  private

  def auth_headers
    { 'Authorization' => "Bearer #{api_key}" }
  end

  # Platform-owned reseller key, not a tenant-supplied BYO credential -- see
  # NumberProvisioning::TelnyxProvider's credential model note in the design doc.
  def api_key
    GlobalConfig.get_value('TELNYX_RESELLER_API_KEY')
  end
end
