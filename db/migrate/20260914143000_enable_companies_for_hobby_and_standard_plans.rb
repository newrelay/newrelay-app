# Companies is core CRM (same as contacts), not a Business-only add-on.
# New Hobby accounts were getting CRM but not Companies because the plan
# matrix and ACCOUNT_LEVEL_FEATURE_DEFAULTS still treated it as premium.
class EnableCompaniesForHobbyAndStandardPlans < ActiveRecord::Migration[7.1]
  def up
    enable_default_feature_flag
    enable_starter_plan_feature
    enable_plan_matrix_rows
    enable_on_existing_accounts
    GlobalConfig.clear_cache
  end

  private

  def enable_default_feature_flag
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    features = config.value.map do |feature|
      next feature unless feature['name'] == 'companies'

      feature.merge('enabled' => true)
    end
    unless features.any? { |feature| feature['name'] == 'companies' }
      features << { 'name' => 'companies', 'display_name' => 'Companies', 'enabled' => true }
    end
    config.update!(value: features)
  end

  def enable_starter_plan_feature
    config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLAN_FEATURES')
    return if config&.value.blank?

    features = config.value.deep_dup
    starter = features['Starter'] || features[:Starter]
    return if starter.blank? || starter.include?('companies')

    insert_at = starter.index('crm')
    if insert_at
      starter.insert(insert_at + 1, 'companies')
    else
      starter << 'companies'
    end
    config.update!(value: features)
  end

  def enable_plan_matrix_rows
    return unless defined?(PlanFeatureLimit)

    %w[hobby standard business].each do |plan_key|
      row = PlanFeatureLimit.find_or_initialize_by(plan_key: plan_key, feature_key: 'companies')
      row.enabled = true
      row.save!
    end
  end

  def enable_on_existing_accounts
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!('companies') }
    end
  end
end
