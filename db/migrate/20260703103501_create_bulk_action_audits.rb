class CreateBulkActionAudits < ActiveRecord::Migration[7.1]
  def change
    create_table :bulk_action_audits do |t|
      t.string :action_label, null: false
      t.string :operation_type, null: false
      t.integer :status, default: 0, null: false # pending: 0, processing: 1, completed: 2, failed: 3
      t.bigint :user_id, null: false
      t.bigint :account_id, null: false
      t.jsonb :statistics, default: {}
      t.datetime :completed_at

      t.timestamps
    end
    add_index :bulk_action_audits, :account_id
    add_index :bulk_action_audits, :user_id
  end
end
