class AddElevenlabsWebhookToChannelTwilioSms < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_twilio_sms, :elevenlabs_webhook_id, :string
    add_column :channel_twilio_sms, :elevenlabs_webhook_secret, :string
  end
end