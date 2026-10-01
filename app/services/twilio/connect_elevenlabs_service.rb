class Twilio::ConnectElevenlabsService
  class Error < StandardError; end

  ELEVENLABS_PHONE_NUMBERS_URL = 'https://api.elevenlabs.io/v1/convai/phone-numbers'.freeze

  pattr_initialize [:inbox!]

  def perform
    channel = inbox.channel
    unless channel.is_a?(Channel::TwilioSms) && channel.phone_number.present?
      raise Error, 'voice_agent_not_twilio'
    end
    return channel if channel.elevenlabs_phone_number_id.present?

    hook = elevenlabs_hook
    raise Error, 'voice_agent_credentials_missing' if hook.blank?

    channel.update!(elevenlabs_phone_number_id: import_number(channel, hook))
    channel
  end

  private

  def elevenlabs_hook
    hook = inbox.account.hooks.find_by(app_id: 'elevenlabs', status: 'enabled')
    hook if hook&.settings&.dig('api_key').present?
  end

  def import_number(channel, hook)
    response = HTTParty.post(
      ELEVENLABS_PHONE_NUMBERS_URL,
      headers: {
        'xi-api-key' => hook.settings['api_key'],
        'Content-Type' => 'application/json'
      },
      body: channel.elevenlabs_import_params(channel.phone_number).to_json,
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