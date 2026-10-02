class Twilio::CreateElevenlabsVoiceJob < ApplicationJob
  queue_as :default

  def perform(elevenlabs_voice_id)
    voice = ElevenlabsVoice.find_by(id: elevenlabs_voice_id)
    return if voice.blank? || !voice.pending?

    Twilio::ElevenlabsVoicesService.new(account: voice.account).create_remote(voice)
  end
end
