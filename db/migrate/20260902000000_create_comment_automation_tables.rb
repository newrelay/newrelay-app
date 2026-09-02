class CreateCommentAutomationTables < ActiveRecord::Migration[7.1]
  def change
    create_table :comment_automation_campaigns do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.string :name, null: false
      t.string :post_id, null: false
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    add_index :comment_automation_campaigns, [:account_id, :post_id]

    create_table :comment_automation_triggers do |t|
      t.references :campaign, null: false, foreign_key: { to_table: :comment_automation_campaigns }
      t.references :account, null: false, foreign_key: true
      t.string :keyword
      t.integer :match_type, null: false, default: 0
      t.text :public_replies, array: true, null: false, default: []
      t.text :dm_text_body, null: false
      t.timestamps
    end

    create_table :comment_automation_message_logs do |t|
      t.references :trigger, null: false, foreign_key: { to_table: :comment_automation_triggers }
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :contact, foreign_key: true
      t.string :comment_id, null: false
      t.string :commenter_id, null: false
      t.integer :status, null: false, default: 0
      t.datetime :sent_at
      t.timestamps
    end
    add_index :comment_automation_message_logs, [:inbox_id, :comment_id], unique: true, name: 'index_ca_msg_logs_on_inbox_comment'
  end
end
