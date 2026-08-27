class AddQuietHoursToNotificationSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :notification_settings, :quiet_hours_enabled, :boolean, default: false, null: false
    add_column :notification_settings, :quiet_hours_from_hour, :integer
    add_column :notification_settings, :quiet_hours_from_minute, :integer
    add_column :notification_settings, :quiet_hours_to_hour, :integer
    add_column :notification_settings, :quiet_hours_to_minute, :integer
    add_column :notification_settings, :quiet_hours_timezone, :string
    add_column :notification_settings, :quiet_hours_days, :integer, default: 0, null: false
  end
end
