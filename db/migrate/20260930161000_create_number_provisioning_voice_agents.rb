class CreateNumberProvisioningVoiceAgents < ActiveRecord::Migration[7.1]
  def change
    create_table :number_provisioning_voice_agents do |t|
      t.references :account, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: { to_table: :number_provisioning_orders }, index: { unique: true }
      t.string :public_id, null: false
      t.string :status, null: false, default: 'saved'
      t.string :failure_code
      # nil until a later flip reads the live carrier route. Connect does not call the carrier.
      t.string :previous_sip_target

      t.timestamps
    end

    add_index :number_provisioning_voice_agents, :public_id, unique: true
  end
end
