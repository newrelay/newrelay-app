class AddToneAndPersonaToElevenlabsVoices < ActiveRecord::Migration[7.1]
  def change
    add_column :elevenlabs_voices, :tone, :string
    add_column :elevenlabs_voices, :persona, :text
  end
end
