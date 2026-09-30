# India leg: Exotel has SIP trunk support and DLT-compliant SMS/WhatsApp
# for India numbers (unlike Telnyx, which has none there). Endpoints
# verified live against Exotel's v2_beta API during integration testing.
class NumberProvisioning::ExotelProvider
  include NumberProvisioning::Provider
  pattr_initialize [:account!]

  BASE_URL = 'https://api.exotel.com/v2_beta'.freeze
  PROVIDER_TYPE = 'exotel'.freeze
  REQUEST_TIMEOUT = 15

  COUNTRY_CODE_FORMAT = /\A[A-Z]{2}\z/
  VALID_NUMBER_TYPES   = %w[Mobile Local TollFree].freeze

  def search(country_code:, type: 'Mobile')
    raise ArgumentError, "Invalid country_code: #{country_code.inspect}" unless country_code.to_s.match?(COUNTRY_CODE_FORMAT)
    raise ArgumentError, "Invalid type: #{type.inspect}" unless VALID_NUMBER_TYPES.include?(type.to_s)

    numbers = if NumberProvisioning::DummyExotel.enabled?
                Rails.logger.info('[NumberProvisioning] exotel dummy search')
                NumberProvisioning::DummyExotel.search
              else
                response = HTTParty.get(
                  "#{BASE_URL}/Accounts/#{account_sid}/AvailablePhoneNumbers/#{country_code}/#{type}",
                  basic_auth: basic_auth,
                  timeout: REQUEST_TIMEOUT
                )
                assert_success!(response, 'Exotel search')
                Array(response.parsed_response)
              end

    numbers.map { |number| normalize_search_result(number) }
  end

  def order(phone_number:)
    return NumberProvisioning::DummyExotel.order(phone_number) if NumberProvisioning::DummyExotel.enabled?

    response = HTTParty.post(
      "#{BASE_URL}/Accounts/#{account_sid}/IncomingPhoneNumbers",
      basic_auth: basic_auth,
      body: { PhoneNumber: phone_number },
      timeout: REQUEST_TIMEOUT
    )
    assert_success!(response, 'Exotel order')

    parsed = response.parsed_response
    # v2_beta returns a flat object with the number's id at top-level `sid`
    # (Purchase ExoPhone docs: { sid, phone_number, capabilities, rental_price,
    # currency }). Older/v1 responses nested it under PhoneNumber.Sid -- read the
    # flat shape first, fall back to the nested one, so provider_order_id is never
    # silently nil (which would strand PollOrderStatusJob's status lookups).
    # Normalize to the {'id' => ...} shape provider_order_id_from expects, matching
    # what TelnyxProvider returns after unwrapping ['data'].
    parsed.merge('id' => parsed['sid'] || parsed.dig('PhoneNumber', 'Sid'))
  end

  def status(provider_order_id:)
    return NumberProvisioning::DummyExotel.status(provider_order_id) if NumberProvisioning::DummyExotel.enabled?

    response = HTTParty.get(
      "#{BASE_URL}/Accounts/#{account_sid}/IncomingPhoneNumbers/#{provider_order_id}",
      basic_auth: basic_auth,
      timeout: REQUEST_TIMEOUT
    )
    assert_success!(response, 'Exotel status check')

    body = response.parsed_response
    keys = body.is_a?(Hash) ? body.keys : body.class.name
    # No captured success body yet, so this stays in progress and is not charged.
    Rails.logger.info("[NumberProvisioning] exotel status keys=#{keys} order_id=#{provider_order_id}")
    { 'status' => 'order_placed' }
  end

  def release(phone_number:, provider_order_id:)
    return NumberProvisioning::DummyExotel.release(provider_order_id) if NumberProvisioning::DummyExotel.enabled?
    return false if provider_order_id.blank?

    response = HTTParty.delete(
      "#{BASE_URL}/Accounts/#{account_sid}/IncomingPhoneNumbers/#{provider_order_id}",
      basic_auth: basic_auth,
      timeout: REQUEST_TIMEOUT
    )
    response.success?
  rescue StandardError => e
    Rails.logger.info("[NumberProvisioning] exotel release failed phone=#{phone_number} error=#{e.class}")
    false
  end

  private

  # Common shape every adapter returns from search() (see TelnyxProvider). Exotel:
  # price under rental_price, capabilities as a { sms:, voice: } boolean object ->
  # a list of the enabled capability names.
  def normalize_search_result(number)
    capabilities = number['capabilities']
    enabled = capabilities.is_a?(Hash) ? capabilities.select { |_name, on| on }.keys : Array(capabilities)
    {
      phone_number: number['phone_number'] || number['PhoneNumber'],
      monthly_price_cents: price_to_cents(number['rental_price']),
      currency: number['currency'] || NumberProvisioning::ProviderConfig.currency_for(PROVIDER_TYPE),
      capabilities: enabled.map(&:to_s)
    }
  end

  def basic_auth
    { username: GlobalConfig.get_value('EXOTEL_RESELLER_API_KEY'), password: GlobalConfig.get_value('EXOTEL_RESELLER_API_TOKEN') }
  end

  # Platform-owned reseller credential, not a tenant-supplied BYO hook -- matches
  # TelnyxProvider's credential model (see agent decision log, 2026-09-28: resolves
  # the credential model the ADR previously left unresolved).
  def account_sid
    GlobalConfig.get_value('EXOTEL_RESELLER_ACCOUNT_SID')
  end
end
