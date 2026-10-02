class Twilio::AssignElevenlabsVoiceService
  pattr_initialize [:inbox!, :voice_id!]

  def perform
    channel = inbox.channel
    raise Twilio::ConnectElevenlabsService::Error, 'voice_agent_not_twilio' unless channel.is_a?(Channel::TwilioSms)
    raise Twilio::ConnectElevenlabsService::Error, 'voice_not_selectable' unless selectable?

    previous = channel.elevenlabs_voice_id
    channel.update!(elevenlabs_voice_id: voice_id)
    return channel if channel.elevenlabs_agent_id.blank?

    begin
      hook = elevenlabs_hook
      Twilio::ElevenlabsVoicesService.new(account: inbox.account).apply_voice(hook, channel.elevenlabs_agent_id, voice_id)
    rescue Twilio::ConnectElevenlabsService::Error
      channel.update!(elevenlabs_voice_id: previous)
      raise
    end
    channel
  end

  private

  def selectable?
    payload = Twilio::ElevenlabsVoicesService.new(account: inbox.account).list
    raise Twilio::ConnectElevenlabsService::Error, 'voice_agent_credentials_missing' unless payload[:connected]

    payload[:voices].any? { |voice| voice[:voice_id] == voice_id && voice[:selectable] }
  end

  def elevenlabs_hook
    hook = inbox.account.hooks.find_by(app_id: 'elevenlabs', status: 'enabled')
    raise Twilio::ConnectElevenlabsService::Error, 'voice_agent_credentials_missing' if hook&.settings&.dig('api_key').blank?

    hook
  end
end
