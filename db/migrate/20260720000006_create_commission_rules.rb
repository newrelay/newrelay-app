class CreateCommissionRules < ActiveRecord::Migration[7.1]
  def change
    create_table :commission_rules do |t|
      t.references :account, null: false, foreign_key: true
      t.decimal :commission_percent, precision: 5, scale: 2, null: false, default: 30.0
      t.datetime :effective_from, null: false
      t.references :created_by_user, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
  end
end
