class Twilio::ConnectElevenlabsService
  class Error < StandardError; end

  ELEVENLABS_PHONE_NUMBERS_URL = 'https://api.elevenlabs.io/v1/convai/phone-numbers'.freeze
  ELEVENLABS_AGENTS_URL = 'https://api.elevenlabs.io/v1/convai/agents'.freeze

  pattr_initialize [:inbox!]

  def perform
    channel = inbox.channel
    unless channel.is_a?(Channel::TwilioSms) && channel.phone_number.present?
      raise Error, 'voice_agent_not_twilio'
    end

    hook = elevenlabs_hook
    raise Error, 'voice_agent_credentials_missing' if hook.blank?

    agent_id = ensure_agent(channel, hook)
    if channel.elevenlabs_phone_number_id.present?
      assign_agent(channel, hook, agent_id)
      return channel
    end

    channel.update!(
      elevenlabs_agent_id: agent_id,
      elevenlabs_phone_number_id: import_number(channel, hook, agent_id)
    )
    channel
  end

  private

  def elevenlabs_hook
    hook = inbox.account.hooks.find_by(app_id: 'elevenlabs', status: 'enabled')
    hook if hook&.settings&.dig('api_key').present?
  end

  def ensure_agent(channel, hook)
    return channel.elevenlabs_agent_id if channel.elevenlabs_agent_id.present?

    agent_id = create_agent(hook)
    channel.update!(elevenlabs_agent_id: agent_id)
    agent_id
  end

  def create_agent(hook)
    voice_id = hook.settings['voice_id'].presence
    response = HTTParty.post(
      "#{ELEVENLABS_AGENTS_URL}/create",
      headers: json_headers(hook),
      body: {
        name: inbox.name.presence || inbox.channel.phone_number,
        conversation_config: {
          tts: { voice_id: voice_id }.compact,
          agent: {
            first_message: 'Hello, how can I help you?',
            prompt: {
              prompt: 'You answer phone calls. Pick up, greet the caller, listen, and reply in short spoken sentences.'
            }
          }
        }
      }.to_json,
      timeout: 20
    )
    agent_id = response.parsed_response['agent_id'] if response.success? && response.parsed_response.is_a?(Hash)
    return agent_id if agent_id.present?

    Rails.logger.info("[voice_agent] elevenlabs_agent_failed inbox_id=#{inbox.id} status=#{response.code}")
    raise Error, 'voice_agent_twilio_rejected'
  rescue Error
    raise
  rescue StandardError
    Rails.logger.info("[voice_agent] elevenlabs_agent_failed inbox_id=#{inbox.id} status=exception")
    raise Error, 'voice_agent_twilio_rejected'
  end

  def import_number(channel, hook, agent_id)
    response = HTTParty.post(
      ELEVENLABS_PHONE_NUMBERS_URL,
      headers: json_headers(hook),
      body: channel.elevenlabs_import_params(channel.phone_number, agent_id: agent_id).to_json,
      timeout: 20
    )
    phone_number_id = parsed_phone_number_id(response)
    return phone_number_id if response.success? && phone_number_id.present?

    Rails.logger.info(
      "[voice_agent] elevenlabs_import_failed inbox_id=#{inbox.id} status=#{response.code} detail=#{safe_detail(response)}"
    )
    raise Error, 'voice_agent_twilio_rejected'
  rescue Error
    raise
  rescue StandardError
    Rails.logger.info("[voice_agent] elevenlabs_import_failed inbox_id=#{inbox.id} status=exception")
    raise Error, 'voice_agent_twilio_rejected'
  end

  def assign_agent(channel, hook, agent_id)
    response = HTTParty.patch(
      "#{ELEVENLABS_PHONE_NUMBERS_URL}/#{channel.elevenlabs_phone_number_id}",
      headers: json_headers(hook),
      body: { agent_id: agent_id }.to_json,
      timeout: 20
    )
    return if response.success?

    Rails.logger.info("[voice_agent] elevenlabs_assign_failed inbox_id=#{inbox.id} status=#{response.code}")
    raise Error, 'voice_agent_twilio_rejected'
  rescue Error
    raise
  rescue StandardError
    Rails.logger.info("[voice_agent] elevenlabs_assign_failed inbox_id=#{inbox.id} status=exception")
    raise Error, 'voice_agent_twilio_rejected'
  end

  def json_headers(hook)
    {
      'xi-api-key' => hook.settings['api_key'],
      'Content-Type' => 'application/json'
    }
  end

  def parsed_phone_number_id(response)
    body = response.parsed_response
    body = JSON.parse(body) if body.is_a?(String)
    body['phone_number_id'] if body.is_a?(Hash)
  rescue JSON::ParserError
    nil
  end

  def safe_detail(response)
    body = response.parsed_response
    return 'unparsed' unless body.is_a?(Hash)

    Array(body['detail']).filter_map { |item| item['msg'] if item.is_a?(Hash) }.join('; ').presence || 'none'
  end
end