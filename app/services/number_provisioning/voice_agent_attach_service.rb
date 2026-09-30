class NumberProvisioning::VoiceAgentAttachService
  class Error < StandardError; end

  ELEVENLABS_PHONE_NUMBERS_URL = 'https://api.elevenlabs.io/v1/convai/phone-numbers'.freeze

  pattr_initialize [:order!]

  def perform
    existing = order.voice_agent
    return existing if existing&.status == 'saved'

    unless order.status == 'active'
      log_failure('voice_agent_not_active', existing)
      raise Error, 'voice_agent_not_active'
    end

    failure = precondition_failure
    if failure
      row = persist_failure(existing, failure)
      log_failure(failure, row)
      raise Error, failure
    end

    save_row(existing, import_twilio_number(existing))
  rescue ActiveRecord::RecordNotUnique
    order.reload.voice_agent
  end

  private

  def precondition_failure
    return 'voice_agent_credentials_missing' if elevenlabs_hook.blank?
    return 'voice_agent_brain_missing' if brain.blank?

    nil
  end

  def elevenlabs_hook
    hook = order.account.hooks.find_by(app_id: 'elevenlabs', status: 'enabled')
    hook if hook&.settings&.dig('api_key').present?
  end

  def brain
    inbox = order.inbox
    return unless inbox.respond_to?(:captain_assistant)

    inbox.captain_assistant
  end

  def import_twilio_number(existing)
    channel = twilio_channel
    return if channel.blank?

    sid, token = twilio_sid_and_token(channel)
    response = HTTParty.post(
      ELEVENLABS_PHONE_NUMBERS_URL,
      headers: {
        'xi-api-key' => elevenlabs_hook.settings['api_key'],
        'Content-Type' => 'application/json'
      },
      body: {
        provider: 'twilio',
        phone_number: order.phone_number,
        label: order.phone_number,
        sid: sid,
        token: token
      }.to_json,
      timeout: 20
    )
    return response.parsed_response['phone_number_id'] if response.success?

    Rails.logger.info("[voice_agent] elevenlabs_import_failed order_id=#{order.id} status=#{response.code}")
    row = persist_failure(existing, 'voice_agent_twilio_rejected')
    log_failure('voice_agent_twilio_rejected', row)
    raise Error, 'voice_agent_twilio_rejected'
  rescue Error
    raise
  rescue StandardError
    Rails.logger.info("[voice_agent] elevenlabs_import_failed order_id=#{order.id} status=exception")
    row = persist_failure(existing, 'voice_agent_twilio_rejected')
    log_failure('voice_agent_twilio_rejected', row)
    raise Error, 'voice_agent_twilio_rejected'
  end

  def twilio_channel
    Channel::TwilioSms.find_by(account_id: order.account_id, phone_number: order.phone_number)
  end

  def twilio_sid_and_token(channel)
    if channel.api_key_sid.present? && channel.api_key_secret.present?
      [channel.api_key_sid, channel.api_key_secret]
    else
      [channel.account_sid, channel.auth_token]
    end
  end

  def save_row(existing, elevenlabs_phone_number_id)
    attrs = { status: 'saved', failure_code: nil, elevenlabs_phone_number_id: elevenlabs_phone_number_id }
    if existing
      existing.update!(attrs)
      existing
    else
      order.create_voice_agent!(attrs.merge(account: order.account))
    end
  end

  def persist_failure(existing, code)
    if existing
      existing.update!(status: 'failed', failure_code: code)
      existing
    else
      order.create_voice_agent!(account: order.account, status: 'failed', failure_code: code)
    end
  end

  def log_failure(code, row)
    Rails.logger.info(
      "[voice_agent] order_id=#{order.id} account_id=#{order.account_id} " \
      "voice_agent_id=#{row&.id} failure_code=#{code}"
    )
  end
end
