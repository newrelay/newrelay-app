class AddSslSettingsToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :ssl_settings, :jsonb, default: {}
  end
end
