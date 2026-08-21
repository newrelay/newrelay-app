class CreateReputationListings < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_listings do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.string :address
      t.string :category
      t.string :country
      t.string :phone
      t.string :website
      t.string :email
      t.boolean :primary, null: false, default: false
      t.jsonb :platforms, null: false, default: []
      t.datetime :synced_at
      t.timestamps
    end
  end
end
