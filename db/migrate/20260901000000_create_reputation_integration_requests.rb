class CreateReputationIntegrationRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_integration_requests do |t|
      t.references :account, null: false, foreign_key: true
      t.string :platform, null: false
      t.string :email
      t.text :notes
      t.timestamps
    end
  end
end
