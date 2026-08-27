class CreateReputationSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_settings do |t|
      t.references :account, null: false, index: { unique: true }
      t.jsonb :config, null: false, default: {}
      t.timestamps
    end
  end
end
