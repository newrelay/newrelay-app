class AddElevenlabsAgentIdToChannelTwilioSms < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_twilio_sms, :elevenlabs_agent_id, :string
  end
end