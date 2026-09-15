class AddNotifiedAtToCaptainActivityLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_activity_logs, :notified_at, :datetime
    add_index :captain_activity_logs, :notified_at
  end
end
