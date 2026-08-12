class AddGracePeriodToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :grace_period_ends_at, :datetime
  end
end
