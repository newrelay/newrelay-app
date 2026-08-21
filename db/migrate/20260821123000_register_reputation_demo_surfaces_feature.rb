# frozen_string_literal: true

# Registers reputation_demo_surfaces on ACCOUNT_LEVEL_FEATURE_DEFAULTS (off)
# and PlanFeatureLimit so Super Admin → Accounts / Plan Management can find it.
# Does not enable the flag on existing accounts.
class RegisterReputationDemoSurfacesFeature < ActiveRecord::Migration[7.1]
  FEATURE = {
    'name' => 'reputation_demo_surfaces',
    'display_name' => 'Reputation Demo Surfaces',
    'enabled' => false
  }.freeze

  def up
    config = InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    features = Array(config.value)
    unless features.any? { |f| f['name'] == FEATURE['name'] || f[:name] == FEATURE['name'] }
      features << FEATURE
      config.value = features
      config.save!
    end

    if defined?(PlanFeatureLimit)
      %w[hobby standard business enterprise].each do |plan_key|
        PlanFeatureLimit.find_or_create_by!(plan_key: plan_key, feature_key: FEATURE['name']) do |row|
          row.enabled = false
        end
      end
    end

    GlobalConfig.clear_cache
  end

  def down
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config&.value.present?
      config.value = config.value.reject { |f| (f['name'] || f[:name]) == FEATURE['name'] }
      config.save!
    end

    PlanFeatureLimit.where(feature_key: FEATURE['name']).delete_all if defined?(PlanFeatureLimit)
    GlobalConfig.clear_cache
  end
end
