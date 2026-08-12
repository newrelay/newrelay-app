class CreateReputationIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_integrations do |t|
      t.references :account, null: false, index: true
      t.string :provider, null: false       # 'google' | 'facebook'
      t.string :location_id, null: false    # GBP location or FB page id
      t.string :location_name
      t.text :access_token                  # encrypted at model layer
      t.text :refresh_token                 # encrypted at model layer
      t.datetime :token_expires_at
      t.string :status, default: 'active'   # 'active' | 'disconnected'
      t.timestamps
    end
    add_index :reputation_integrations, [:account_id, :provider, :location_id], unique: true,
                                                                                name: 'idx_reputation_integrations_unique'
  end
end
