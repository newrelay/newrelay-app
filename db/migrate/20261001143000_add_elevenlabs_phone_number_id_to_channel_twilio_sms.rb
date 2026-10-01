class AddElevenlabsPhoneNumberIdToChannelTwilioSms < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_twilio_sms, :elevenlabs_phone_number_id, :string
  end
end