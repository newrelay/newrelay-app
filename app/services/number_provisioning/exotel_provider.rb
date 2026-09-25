# India leg: Exotel has SIP trunk support and DLT-compliant SMS/WhatsApp
# for India numbers (unlike Telnyx, which has none there). Endpoints
# verified live against Exotel's v2_beta API during integration testing.
class NumberProvisioning::ExotelProvider
  include NumberProvisioning::Provider
  pattr_initialize [:account!]

  BASE_URL = 'https://api.exotel.com/v2_beta'.freeze

  def search(country_code:, type: 'Mobile')
    response = HTTParty.get(
      "#{BASE_URL}/Accounts/#{account_sid}/AvailablePhoneNumbers/#{country_code}/#{type}",
      basic_auth: basic_auth
    )
    raise "Exotel search failed: #{response.body}" unless response.success?

    response.parsed_response
  end

  def order(phone_number:)
    response = HTTParty.post(
      "#{BASE_URL}/Accounts/#{account_sid}/IncomingPhoneNumbers",
      basic_auth: basic_auth,
      body: { PhoneNumber: phone_number }
    )
    raise "Exotel order failed: #{response.body}" unless response.success?

    response.parsed_response
  end

  def status(provider_order_id:)
    response = HTTParty.get(
      "#{BASE_URL}/Accounts/#{account_sid}/IncomingPhoneNumbers/#{provider_order_id}",
      basic_auth: basic_auth
    )
    raise "Exotel status check failed: #{response.body}" unless response.success?

    response.parsed_response
  end

  private

  def basic_auth
    { username: credentials['api_key'], password: credentials['api_token'] }
  end

  def account_sid
    credentials['account_sid']
  end

  def credentials
    account.hooks.find_by(app_id: 'exotel', status: 'enabled')&.settings || {}
  end
end
