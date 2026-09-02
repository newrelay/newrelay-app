class CreateCommentAutomationTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :comment_automation_templates do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :template_type, null: false, default: 0
      t.text :public_replies, array: true, null: false, default: []
      t.text :dm_text_body
      t.boolean :favorite, null: false, default: false
      t.timestamps
    end

    add_reference :comment_automation_triggers, :template, foreign_key: { to_table: :comment_automation_templates }
  end
end
