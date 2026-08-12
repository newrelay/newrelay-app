class CreateConnectedAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :connected_accounts do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :stripe_account_id, null: false
      t.string :country, null: false
      t.string :charge_routing, null: false
      t.string :onboarding_status, null: false, default: 'onboarding_incomplete'
      t.boolean :charges_enabled, default: false
      t.boolean :payouts_enabled, default: false
      t.timestamps
    end

    add_index :connected_accounts, :stripe_account_id, unique: true
  end
end
