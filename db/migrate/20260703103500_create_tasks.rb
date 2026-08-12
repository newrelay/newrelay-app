class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.boolean :completed, default: false, null: false
      t.datetime :due_at
      t.bigint :assignee_id
      t.bigint :account_id, null: false

      t.timestamps
    end
    add_index :tasks, :account_id
    add_index :tasks, :assignee_id

    # Join table for many-to-many relationship between contacts and tasks
    create_table :contact_tasks do |t|
      t.bigint :contact_id, null: false
      t.bigint :task_id, null: false
    end
    add_index :contact_tasks, [:contact_id, :task_id], unique: true
  end
end
