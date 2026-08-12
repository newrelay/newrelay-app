class RenamePaymentFailureLogsToBillingActivityLogs < ActiveRecord::Migration[7.1]
  def change
    rename_table :payment_failure_logs, :billing_activity_logs
    rename_column :billing_activity_logs, :error_message, :message
    add_column :billing_activity_logs, :status, :string, null: false, default: 'failed'
    add_index :billing_activity_logs, :status
  end
end
