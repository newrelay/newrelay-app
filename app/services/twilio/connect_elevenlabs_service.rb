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
    sid, token = twilio_sid_and_token(channel)
    response = HTTParty.post(
      ELEVENLABS_PHONE_NUMBERS_URL,
      headers: {
        'xi-api-key' => hook.settings['api_key'],
        'Content-Type' => 'application/json'
      },
      body: {
        provider: 'twilio',
        phone_number: channel.phone_number,
        label: channel.phone_number,
        sid: sid,
        token: token
      }.to_json,
      timeout: 20
    )
    return response.parsed_response['phone_number_id'] if response.success?

    Rails.logger.info("[voice_agent] elevenlabs_import_failed inbox_id=#{inbox.id} status=#{response.code}")
    raise Error, 'voice_agent_twilio_rejected'
  rescue Error
    raise
  rescue StandardError
    Rails.logger.info("[voice_agent] elevenlabs_import_failed inbox_id=#{inbox.id} status=exception")
    raise Error, 'voice_agent_twilio_rejected'
  end

  def twilio_sid_and_token(channel)
    if channel.api_key_sid.present? && channel.api_key_secret.present?
      [channel.api_key_sid, channel.api_key_secret]
    else
      [channel.account_sid, channel.auth_token]
    end
  end
end