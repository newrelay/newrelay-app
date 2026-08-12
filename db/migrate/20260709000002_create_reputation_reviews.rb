class CreateReputationReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_reviews do |t|
      t.references :account, null: false, index: true
      t.references :reputation_integration, null: false, index: true
      t.string :external_id, null: false     # platform's review id
      t.string :provider, null: false        # 'google' | 'facebook'
      t.integer :rating                      # 1-5
      t.text :body
      t.string :reviewer_name
      t.string :status, default: 'pending'   # 'pending' | 'replied' | 'ignored'
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :reputation_reviews, [:account_id, :external_id, :provider], unique: true,
                                                                           name: 'idx_reputation_reviews_unique'
    add_index :reputation_reviews, [:account_id, :status]
  end
end
