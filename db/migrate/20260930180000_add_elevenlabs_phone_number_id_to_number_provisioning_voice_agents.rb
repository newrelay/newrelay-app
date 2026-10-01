class AddElevenlabsPhoneNumberIdToNumberProvisioningVoiceAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :number_provisioning_voice_agents, :elevenlabs_phone_number_id, :string
  end
end
