class CreateCaptainActivityLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_activity_logs do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id
      t.string :action, null: false
      t.string :status, null: false, default: 'failed'
      t.string :error_class
      t.text :message, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :captain_activity_logs, :account_id
    add_index :captain_activity_logs, :user_id
    add_index :captain_activity_logs, :action
    add_index :captain_activity_logs, :status
    add_index :captain_activity_logs, :created_at

    add_foreign_key :captain_activity_logs, :accounts
    add_foreign_key :captain_activity_logs, :users
  end
end
