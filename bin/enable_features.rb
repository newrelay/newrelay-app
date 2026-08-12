# frozen_string_literal: true

# 1. Ensure the installation pricing plan and deployment environment are set to enterprise self-hosted
config_env = InstallationConfig.find_or_initialize_by(name: 'DEPLOYMENT_ENV')
config_env.value = 'self-hosted'
config_env.save!

config_plan = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
config_plan.value = 'enterprise'
config_plan.save!

config_qty = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
config_qty.value = 1000
config_qty.save!

# Enable additional account creation from dashboard
config_create = InstallationConfig.find_or_initialize_by(name: 'CREATE_NEW_ACCOUNT_FROM_DASHBOARD')
config_create.value = true
config_create.save!

# 2. Configure ACCOUNT_LEVEL_FEATURE_DEFAULTS to enable ALL features for all new accounts by default
all_features_defaults = Featurable::FEATURE_LIST.map { |f| { name: f['name'], enabled: true } }
config_defaults = InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
config_defaults.value = all_features_defaults
config_defaults.save!

# Clear global config cache to apply configs
GlobalConfig.clear_cache

# 3. Create/link the first account and user if not present
account = Account.first || Account.create!(name: 'My Business')
user = User.find_by(email: 'admin@mybusiness.com')
if user.blank?
  user = User.new(email: 'admin@mybusiness.com', name: 'Administrator', password: 'Password123!', type: 'SuperAdmin')
  user.skip_confirmation!
  user.save!
end

unless AccountUser.exists?(account_id: account.id, user_id: user.id)
  AccountUser.create!(account_id: account.id, user_id: user.id, role: :administrator)
end

# 4. Enable all features (standard & AI) for ALL existing accounts
feature_names = Featurable::FEATURE_LIST.pluck('name')
ai_features = {}
Llm::Models.feature_keys.each { |key| ai_features[key] = true }

Account.all.each do |acc|
  acc.enable_features!(*feature_names)
  acc.update!(captain_features: ai_features)
end

puts 'SuperAdmin, Enterprise settings, default features, and all existing accounts successfully configured with premium features!'
