class AddNotifiedAtToBillingActivityLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :billing_activity_logs, :notified_at, :datetime
    add_index :billing_activity_logs, :notified_at
  end
end
