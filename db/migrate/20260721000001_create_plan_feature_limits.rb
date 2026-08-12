class CreatePlanFeatureLimits < ActiveRecord::Migration[7.0]
  def change
    create_table :plan_feature_limits do |t|
      t.string :plan_key, null: false        # 'hobby', 'standard', 'business', 'enterprise'
      t.string :feature_key, null: false     # feature flag name or resource limit name
      t.boolean :enabled, null: false, default: false
      t.integer :limit_value                  # nil = unlimited
      t.timestamps
    end
    add_index :plan_feature_limits, [:plan_key, :feature_key], unique: true
  end
end
