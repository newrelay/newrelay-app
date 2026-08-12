class SuperAdmin::PlanManagementController < SuperAdmin::ApplicationController
  PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'

  def show
    load_plans
    load_all_features
    load_limits
    load_plan_feature_limits
  end

  def update
    save_plans
    save_plan_feature_limits
    redirect_to super_admin_plan_management_path, notice: 'Plans and feature limits updated successfully.'
  end

  private

  def load_plans
    config = InstallationConfig.find_by(name: PLANS_CONFIG)
    @plans = config&.value || []
    return unless @plans.empty? || @plans.size < 4

    seed_default_plans!
  end

  def load_all_features
    @all_features = YAML.load_file(Rails.root.join('config/features.yml'))
                        .reject { |f| f['deprecated'] }
                        .map { |f| { 'name' => f['name'], 'display_name' => f['display_name'] } }
  end

  def load_limits
    @limits = [
      { 'name' => 'seats', 'display_name' => 'Seats (team members)' },
      { 'name' => 'contacts', 'display_name' => 'Contacts' },
      { 'name' => 'conversations', 'display_name' => 'Conversations/month' },
      { 'name' => 't3_subaccounts', 'display_name' => 'T3 reseller sub-accounts' },
      { 'name' => 'automations', 'display_name' => 'Automations/workflows' },
      { 'name' => 'captain_documents', 'display_name' => 'Captain AI documents' },
      { 'name' => 'captain_responses', 'display_name' => 'Captain AI credits (responses)/month' },
      { 'name' => 'data_retention_months', 'display_name' => 'Data retention (months)' }
    ]
  end

  def load_plan_feature_limits
    seed_default_limits! if PlanFeatureLimit.count.zero?

    @plan_feature_limits = {}
    PlanFeatureLimit.all.each do |pfl|
      @plan_feature_limits[[pfl.plan_key, pfl.feature_key]] = pfl
    end
  end

  def save_plans
    plans_param = params[:plans] || {}
    config = InstallationConfig.find_or_initialize_by(name: PLANS_CONFIG)
    config.serialized_value = {}.with_indifferent_access if config.serialized_value.blank?

    if config.value.blank?
      config.value = [
        { 'name' => 'Hobby', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 0, 'enabled' => true },
        { 'name' => 'Standard', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 10, 'enabled' => true },
        { 'name' => 'Business', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 49, 'enabled' => true },
        { 'name' => 'Enterprise', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 0, 'enabled' => true }
      ]
    end

    updated_plans = config.value.map do |plan|
      plan_data = plans_param[plan['name']]
      next plan unless plan_data

      gw_prices_param = plan_data[:gateway_prices] || {}
      gateway_prices = {}

      Enterprise::Billing::PaymentGatewayRegistry.definitions.each do |gateway_id, definition|
        gw_data = gw_prices_param[gateway_id] || {}
        amount = gw_data[:amount].to_f
        plan_id = gw_data[:plan_id].presence

        gateway_prices[gateway_id.to_s] = {
          'amount' => amount,
          'currency' => definition[:currency],
          'price_id' => plan_id,
          'plan_id' => plan_id
        }
      end

      stripe_gw = gateway_prices['stripe'] || {}
      razorpay_gw = gateway_prices['razorpay'] || {}

      plan.merge(
        'price_per_agent' => stripe_gw['amount'].to_f,
        'enabled' => plan_data[:enabled] == '1',
        'price_ids' => stripe_gw['price_id'].present? ? [stripe_gw['price_id']] : [],
        'razorpay_plan_ids' => razorpay_gw['plan_id'].present? ? [razorpay_gw['plan_id']] : [],
        'gateway_prices' => gateway_prices
      )
    end

    config.value = updated_plans
    config.save!
  end

  def save_plan_feature_limits
    features_param = params[:plan_features] || {}
    limits_param = params[:plan_limits] || {}

    # Reset all plan feature limits except Enterprise (which is custom per account)
    PlanFeatureLimit.where.not(plan_key: 'enterprise').update_all(enabled: false)

    # 1. Update enabled boolean features
    features_param.each do |plan_key, features|
      features.each do |feature_key, enabled_val|
        pfl = PlanFeatureLimit.find_or_initialize_by(plan_key: plan_key.downcase, feature_key: feature_key)
        pfl.enabled = enabled_val == '1'
        pfl.save!
      end
    end

    # 2. Update numeric limit values
    limits_param.each do |plan_key, limits|
      limits.each do |limit_key, limit_val|
        pfl = PlanFeatureLimit.find_or_initialize_by(plan_key: plan_key.downcase, feature_key: limit_key)
        pfl.enabled = true
        pfl.limit_value = limit_val.present? ? limit_val.to_i : nil
        pfl.save!
      end
    end
  end

  def seed_default_plans!
    plans = [
      { 'name' => 'Hobby', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 0, 'enabled' => true },
      { 'name' => 'Standard', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 10, 'enabled' => true },
      { 'name' => 'Business', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 49, 'enabled' => true },
      { 'name' => 'Enterprise', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 0, 'enabled' => true }
    ]

    config = InstallationConfig.find_or_initialize_by(name: PLANS_CONFIG)
    config.serialized_value = {}.with_indifferent_access if config.serialized_value.blank?
    config.value = plans
    config.save!
    @plans = plans
  end

  def seed_default_limits!
    all_feature_names = YAML.load_file(Rails.root.join('config/features.yml'))
                            .reject { |f| f['deprecated'] }
                            .map { |f| f['name'] }

    plans_keys = %w[hobby standard business enterprise]

    plans_keys.each do |plan_key|
      limits_matrix = {
        'hobby' => { 'seats' => 1, 'contacts' => 500, 'conversations' => 200, 't3_subaccounts' => 0, 'automations' => 3,
                     'captain_documents' => 0, 'captain_responses' => 0, 'data_retention_months' => 1 },
        'standard' => { 'seats' => 5, 'contacts' => 5000, 'conversations' => 2000, 't3_subaccounts' => 3, 'automations' => 15,
                        'captain_documents' => 0, 'captain_responses' => 0, 'data_retention_months' => 6 },
        'business' => { 'seats' => 20, 'contacts' => 50_000, 'conversations' => 20_000, 't3_subaccounts' => 25, 'automations' => 100,
                        'captain_documents' => 200, 'captain_responses' => 300, 'data_retention_months' => 12 },
        'enterprise' => { 'seats' => nil, 'contacts' => nil, 'conversations' => nil, 't3_subaccounts' => nil, 'automations' => nil,
                          'captain_documents' => nil, 'captain_responses' => nil, 'data_retention_months' => nil }
      }

      # Seed features
      all_feature_names.each do |feature_name|
        next if limits_matrix[plan_key].key?(feature_name)

        enabled = true
        enabled = !feature_name.in?(premium_only_features) if plan_key == 'hobby' || plan_key == 'standard'

        PlanFeatureLimit.create!(
          plan_key: plan_key,
          feature_key: feature_name,
          enabled: enabled,
          limit_value: nil
        )
      end

      # Seed resource limits
      limits_matrix[plan_key].each do |limit_key, val|
        enabled = true
        enabled = !limit_key.in?(premium_only_features) if limit_key == 'automations' && (plan_key == 'hobby' || plan_key == 'standard')

        PlanFeatureLimit.create!(
          plan_key: plan_key,
          feature_key: limit_key,
          enabled: enabled,
          limit_value: val
        )
      end
    end
  end

  def premium_only_features
    %w[
      disable_branding audit_logs sla custom_roles captain_integration
      captain_v1_action_classifier help_center_embedding_search custom_tools
      advanced_search advanced_search_indexing saml captain_integration_v2
      captain_document_auto_sync white_labeling custom_domain reseller_dashboard
      api_access companies csat_review_notes conversation_required_attributes
      advanced_assignment channel_voice
    ]
  end
end
