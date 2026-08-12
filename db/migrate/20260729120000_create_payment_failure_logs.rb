class CreatePaymentFailureLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_failure_logs do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :payment_provider
      t.string :error_class
      t.text :error_message, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :payment_failure_logs, :action
    add_index :payment_failure_logs, :created_at
  end
end
