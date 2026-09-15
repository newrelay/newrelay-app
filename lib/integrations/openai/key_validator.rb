module Integrations::Openai::KeyValidator
  TIMEOUT_SECONDS = 5

  def self.valid?(api_key, endpoint: nil)
    return false if api_key.blank?

    connection = Faraday.new do |f|
      f.options.timeout = TIMEOUT_SECONDS
      f.options.open_timeout = TIMEOUT_SECONDS
    end

    response = connection.get(check_url(endpoint)) do |req|
      req.headers['Authorization'] = "Bearer #{api_key}"
    end

    response.status != 401
  rescue Faraday::Error => e
    Rails.logger.warn("[openai-key-validator] #{e.class}: #{e.message}")
    true
  end

  def self.api_base(endpoint_override = nil)
    endpoint = endpoint_override.presence || InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.presence || 'https://api.openai.com/'
    "#{endpoint.chomp('/')}/v1"
  end

  # OpenRouter's /v1/models is public and returns 200 without auth, so it
  # can't tell a dead key from a live one. /v1/key does require auth there.
  def self.check_url(endpoint_override = nil)
    base = api_base(endpoint_override)
    base.include?('openrouter.ai') ? "#{base}/key" : "#{base}/models"
  end
end
