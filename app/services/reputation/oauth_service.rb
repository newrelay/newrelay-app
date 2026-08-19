# Exchanges OAuth code for tokens and persists/updates the Reputation::Integration.
# ponytail: one service per provider call, no factory — add provider registry if >3 providers
class Reputation::OauthService
  PROVIDERS = %w[google facebook].freeze

  def initialize(account:, provider:, code:)
    @account  = account
    @provider = provider
    @code     = code
  end

  def connect!
    raise ArgumentError, "Unknown provider: #{@provider}" unless PROVIDERS.include?(@provider)

    token_data = exchange_code_for_tokens
    upsert_integration(token_data)
    true
  end

  def exchange_google_code_for_tokens
    options = {
      body: {
        code: @code,
        client_id: ENV.fetch('REPUTATION_GOOGLE_CLIENT_ID', nil),
        client_secret: ENV.fetch('REPUTATION_GOOGLE_CLIENT_SECRET', nil),
        redirect_uri: "#{ENV.fetch('FRONTEND_URL', '')}/reputation/oauth/callback?provider=google",
        grant_type: 'authorization_code'
      }
    }
    options[:verify] = false if Rails.env.development?
    response = HTTParty.post('https://oauth2.googleapis.com/token', options)
    raise "Google token error: #{response.body}" unless response.success?

    response.parsed_response
  end

  private

  # Google uses the two-step flow in the callback (exchange_google_code_for_tokens +
  # explicit location selection), so connect! only handles Facebook.
  def exchange_code_for_tokens
    case @provider
    when 'facebook' then exchange_facebook
    end
  end

  def exchange_facebook
    response = HTTParty.get('https://graph.facebook.com/oauth/access_token', query: {
                              client_id: ENV.fetch('REPUTATION_FACEBOOK_APP_ID'),
                              client_secret: ENV.fetch('REPUTATION_FACEBOOK_APP_SECRET'),
                              redirect_uri: "#{ENV.fetch('FRONTEND_URL', '')}/reputation/oauth/callback?provider=facebook",
                              code: @code
                            })
    raise "Facebook token error: #{response.body}" unless response.success?

    page = fetch_facebook_page(response['access_token'])
    response.parsed_response.merge('location_id' => page['id'], 'location_name' => page['name'])
  end

  def fetch_facebook_page(access_token)
    resp = HTTParty.get('https://graph.facebook.com/me/accounts',
                        query: { access_token: access_token, fields: 'id,name' })
    resp.parsed_response.dig('data', 0) || {}
  end

  def upsert_integration(data)
    Reputation::Integration.find_or_initialize_by(
      account: @account,
      provider: @provider,
      location_id: data['location_id']
    ).update!(
      location_name: data['location_name'],
      access_token: data['access_token'],
      refresh_token: data['refresh_token'],
      token_expires_at: data['expires_in'] ? Time.current + data['expires_in'].to_i.seconds : nil,
      status: :active
    )
  end
end
