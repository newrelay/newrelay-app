class CreateReputationListingMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_listing_members do |t|
      t.bigint :account_id, null: false
      t.bigint :reputation_listing_id, null: false
      t.bigint :user_id, null: false
      t.timestamps
    end

    add_index :reputation_listing_members, :account_id
    add_index :reputation_listing_members, :reputation_listing_id
    add_index :reputation_listing_members, %i[reputation_listing_id user_id],
              unique: true, name: 'idx_reputation_listing_members_unique'
  end
end
