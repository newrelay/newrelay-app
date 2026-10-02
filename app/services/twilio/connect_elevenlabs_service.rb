class Twilio::ConnectElevenlabsService
  class Error < StandardError; end

  ELEVENLABS_PHONE_NUMBERS_URL = 'https://api.elevenlabs.io/v1/convai/phone-numbers'.freeze
  ELEVENLABS_AGENTS_URL = 'https://api.elevenlabs.io/v1/convai/agents'.freeze
  ELEVENLABS_WEBHOOKS_URL = 'https://api.elevenlabs.io/v1/workspace/webhooks'.freeze

  pattr_initialize [:inbox!]

  def perform
    channel = inbox.channel
    raise Error, 'voice_agent_not_twilio' unless channel.is_a?(Channel::TwilioSms) && channel.phone_number.present?

    hook = elevenlabs_hook
    raise Error, 'voice_agent_credentials_missing' if hook.blank?

    agent_id = ensure_agent(channel, hook)
    Twilio::ElevenlabsKnowledgeService.new(inbox: inbox, hook: hook, agent_id: agent_id).perform
    phone_number_id = channel.elevenlabs_phone_number_id.presence || import_number(channel, hook, agent_id)
    channel.update!(elevenlabs_agent_id: agent_id, elevenlabs_phone_number_id: phone_number_id)
    assign_agent(channel, hook, agent_id)
    attach_call_log(channel, hook, agent_id)
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
    selected = inbox.channel.elevenlabs_voice_id.presence
    voice_id = selected || hook.settings['voice_id'].presence
    response = post_agent(hook, voice_id)
    agent_id = agent_id_from(response)
    if agent_id.blank? && selected.blank? && hook.settings['voice_id'].present?
      response = post_agent(hook, nil)
      agent_id = agent_id_from(response)
    end
    return agent_id if agent_id.present?

    raise Error, rejection_message(response)
  rescue Error
    raise
  rescue StandardError
    Rails.logger.info("[voice_agent] elevenlabs_agent_failed inbox_id=#{inbox.id} status=exception")
    raise Error, 'voice_agent_twilio_rejected'
  end

  def post_agent(hook, voice_id)
    HTTParty.post(
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

    existing = existing_phone_number_id(channel, hook)
    return existing if existing.present?

    raise Error, rejection_message(response)
  rescue Error
    raise
  rescue StandardError
    Rails.logger.info("[voice_agent] elevenlabs_import_failed inbox_id=#{inbox.id} status=exception")
    raise Error, 'voice_agent_twilio_rejected'
  end

  def existing_phone_number_id(channel, hook)
    response = HTTParty.get(
      ELEVENLABS_PHONE_NUMBERS_URL,
      headers: { 'xi-api-key' => hook.settings['api_key'] },
      timeout: 20
    )
    return unless response.success?

    wanted = channel.phone_number.to_s.gsub(/\D/, '')
    rows = response.parsed_response
    rows = rows['phone_numbers'] if rows.is_a?(Hash)
    match = Array(rows).find { |row| row.is_a?(Hash) && row['phone_number'].to_s.gsub(/\D/, '') == wanted }
    match && match['phone_number_id']
  rescue StandardError
    nil
  end

  def assign_agent(channel, hook, agent_id)
    response = HTTParty.patch(
      "#{ELEVENLABS_PHONE_NUMBERS_URL}/#{channel.elevenlabs_phone_number_id}",
      headers: json_headers(hook),
      body: { agent_id: agent_id }.to_json,
      timeout: 20
    )
    return if response.success?

    raise Error, rejection_message(response)
  rescue Error
    raise
  rescue StandardError
    Rails.logger.info("[voice_agent] elevenlabs_assign_failed inbox_id=#{inbox.id} status=exception")
    raise Error, 'voice_agent_twilio_rejected'
  end

  def attach_call_log(channel, hook, agent_id)
    Twilio::RegisterElevenlabsWebhookService.new(
      inbox: inbox, channel: channel, hook: hook, agent_id: agent_id
    ).perform
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

  def agent_id_from(response)
    body = parsed_body(response)
    body['agent_id'] if response.success? && body.is_a?(Hash)
  end

  def rejection_message(response)
    detail = safe_detail(response)
    Rails.logger.info("[voice_agent] elevenlabs_rejected inbox_id=#{inbox.id} status=#{response.code} detail=#{detail}")
    "ElevenLabs: #{detail}".truncate(180)
  end

  def safe_detail(response)
    body = parsed_body(response)
    return 'unparsed' unless body.is_a?(Hash)

    text = detail_text(body['detail']).presence || body['message'] || body['error']
    sanitize(text.presence || 'none')
  end

  def detail_text(detail)
    return detail if detail.is_a?(String)
    return detail['message'] || detail['status'] || detail['msg'] if detail.is_a?(Hash)

    array_detail(detail)
  end

  def array_detail(detail)
    return unless detail.is_a?(Array)

    detail.filter_map { |item| item.is_a?(Hash) ? item['msg'] : item.to_s }.join('; ')
  end

  def parsed_body(response)
    body = response.parsed_response
    body = JSON.parse(body) if body.is_a?(String)
    body
  rescue JSON::ParserError
    nil
  end

  def sanitize(text)
    hidden = [inbox.channel.auth_token, inbox.channel.api_key_secret, inbox.channel.api_key_sid, inbox.channel.account_sid]
    hidden << inbox.account.hooks.find_by(app_id: 'elevenlabs')&.settings&.dig('api_key')
    hidden.compact.each { |secret| text = text.gsub(secret, '[hidden]') if secret.length > 6 }
    text
  end
end
