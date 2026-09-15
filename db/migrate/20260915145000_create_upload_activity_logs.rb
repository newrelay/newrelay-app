class CreateUploadActivityLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :upload_activity_logs do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id
      t.string :action, null: false
      t.string :status, null: false, default: 'failed'
      t.string :error_class
      t.text :message, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :notified_at

      t.timestamps
    end

    add_index :upload_activity_logs, :account_id
    add_index :upload_activity_logs, :user_id
    add_index :upload_activity_logs, :action
    add_index :upload_activity_logs, :status
    add_index :upload_activity_logs, :notified_at
    add_index :upload_activity_logs, :created_at

    add_foreign_key :upload_activity_logs, :accounts
    add_foreign_key :upload_activity_logs, :users
  end
end
