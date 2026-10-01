# US leg: Telnyx has full SIP trunk support and no DLT-style SMS blocker
# for US numbers (unlike its India numbers, which are voice-only).
class NumberProvisioning::TelnyxProvider
  include NumberProvisioning::Provider
  pattr_initialize [:account!]

  BASE_URL = 'https://api.telnyx.com/v2'.freeze
  PROVIDER_TYPE = 'telnyx'.freeze
  REQUEST_TIMEOUT = 15

  REQUIREMENT_STATUS_MAP = {
    'requirement-info-pending' => 'requirements_pending',
    'requirement-info-under-review' => 'requirements_under_review',
    'requirement-info-exception' => 'requirements_rejected'
  }.freeze
  NUMBER_STATUS_MAP = { 'success' => 'active', 'failure' => 'failed' }.freeze

  def search(country_code:, type: nil)
    response = HTTParty.get(
      "#{BASE_URL}/available_phone_numbers",
      headers: auth_headers,
      query: { 'filter[country_code]' => country_code, 'filter[phone_number_type]' => type, 'filter[limit]' => 20 }.compact,
      timeout: REQUEST_TIMEOUT
    )
    assert_success!(response, 'Telnyx search')

    Array(response.parsed_response['data']).map { |number| normalize_search_result(number) }
  end

  def order(phone_number:)
    response = HTTParty.post(
      "#{BASE_URL}/number_orders",
      headers: auth_headers.merge('Content-Type' => 'application/json'),
      body: { phone_numbers: [{ phone_number: phone_number }] }.to_json,
      timeout: REQUEST_TIMEOUT
    )
    assert_success!(response, 'Telnyx order')

    response.parsed_response['data']
  end

  def status(provider_order_id:)
    response = HTTParty.get(
      "#{BASE_URL}/number_orders/#{provider_order_id}",
      headers: auth_headers,
      timeout: REQUEST_TIMEOUT
    )
    assert_success!(response, 'Telnyx status check')

    { 'status' => map_order_status(response.parsed_response['data']) }
  end

  # Lookup then DELETE /v2/phone_numbers/{id}. A non-success stays billing_failed.
  def release(phone_number:, provider_order_id:)
    listed = HTTParty.get(
      "#{BASE_URL}/phone_numbers",
      headers: auth_headers,
      query: { 'filter[phone_number]' => phone_number },
      timeout: REQUEST_TIMEOUT
    )
    return false unless listed.success?

    phone_id = Array(listed.parsed_response['data']).first&.dig('id')
    return false if phone_id.blank?

    deleted = HTTParty.delete("#{BASE_URL}/phone_numbers/#{phone_id}", headers: auth_headers, timeout: REQUEST_TIMEOUT)
    deleted.success?
  rescue StandardError => e
    Rails.logger.info("[NumberProvisioning] telnyx release failed error=#{e.class}")
    false
  end

  private

  # Common shape every adapter returns from search(), so the controller, the
  # frontend, and cost capture never branch on the provider's raw field names.
  # Telnyx: price under cost_information.monthly_cost/currency, capabilities in
  # a `features` array (strings or {name:}).
  def normalize_search_result(number)
    {
      phone_number: number['phone_number'],
      monthly_price_cents: price_to_cents(number.dig('cost_information', 'monthly_cost')),
      currency: number.dig('cost_information', 'currency') || NumberProvisioning::ProviderConfig.currency_for(PROVIDER_TYPE),
      capabilities: Array(number['features']).map { |feature| feature.is_a?(Hash) ? feature['name'] : feature }.compact
    }
  end

  def map_order_status(data)
    data = data.is_a?(Hash) ? data : {}
    phone = Array(data['phone_numbers']).first || {}
    REQUIREMENT_STATUS_MAP[phone['requirements_status']] ||
      NUMBER_STATUS_MAP[phone['status']] ||
      NUMBER_STATUS_MAP[data['status']] ||
      'order_placed'
  end

  def auth_headers
    { 'Authorization' => "Bearer #{api_key}" }
  end

  # Platform-owned reseller key, not a tenant-supplied BYO credential -- see
  # NumberProvisioning::TelnyxProvider's credential model note in the design doc.
  def api_key
    GlobalConfig.get_value('TELNYX_RESELLER_API_KEY')
  end
end
