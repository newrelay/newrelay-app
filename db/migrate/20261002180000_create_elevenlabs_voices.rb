class CreateElevenlabsVoices < ActiveRecord::Migration[7.1]
  def change
    create_table :elevenlabs_voices do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :voice_id
      t.string :preview_url
      t.string :error_message
      t.string :consent_statement, null: false
      t.datetime :consent_accepted_at, null: false
      t.boolean :requires_verification, null: false, default: false
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :elevenlabs_voices, [:account_id, :voice_id], unique: true, where: 'voice_id IS NOT NULL',
                                                            name: 'index_elevenlabs_voices_on_account_and_voice_id'
    add_column :channel_twilio_sms, :elevenlabs_voice_id, :string
  end
end
