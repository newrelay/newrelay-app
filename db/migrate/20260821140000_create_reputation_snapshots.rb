class CreateReputationSnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :reputation_snapshots do |t|
      t.references :account, null: false, index: true
      t.string :provider, null: false
      t.date :captured_on, null: false
      t.integer :reviews_count, null: false, default: 0
      t.decimal :avg_rating, precision: 3, scale: 2, null: false, default: 0
      t.decimal :response_rate, precision: 5, scale: 2, null: false, default: 0
      t.integer :score, null: false, default: 0
      t.timestamps
    end

    add_index :reputation_snapshots, [:account_id, :provider, :captured_on],
              unique: true, name: 'idx_reputation_snapshots_unique'
  end
end
