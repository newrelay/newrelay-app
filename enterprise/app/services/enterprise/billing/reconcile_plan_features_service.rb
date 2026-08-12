class Enterprise::Billing::ReconcilePlanFeaturesService
  pattr_initialize [:account!]

  def perform
    plan_name = account.custom_attributes['plan_name'].presence || 'Hobby'
    plan_key = plan_name.downcase

    # Fetch baseline features and limits from DB templates
    plan_limits = PlanFeatureLimit.where(plan_key: plan_key).to_a

    # Unknown plans (e.g. the reseller 'Marketplace Plan') have no matrix rows.
    # Skip reconciliation so we don't wipe an account's features and limits.
    return if plan_limits.empty?

    enabled_features = []
    limits_hash = {}

    plan_limits.each do |pfl|
      if PlanFeatureLimit::RESOURCE_LIMIT_KEYS.include?(pfl.feature_key)
        # It's a resource limit
        limits_hash[pfl.feature_key] = pfl.limit_value
      elsif pfl.enabled
        # It's a boolean feature flag
        enabled_features << pfl.feature_key
      end
    end

    # Apply active EnterpriseContract overrides if plan is Enterprise
    if plan_key == 'enterprise'
      active_contract = EnterpriseContract.active.find_by(account_id: account.id)
      if active_contract.present?
        active_contract.negotiated_limit_overrides.each do |key, value|
          limits_hash[key] = value
        end

        enabled_features = active_contract.negotiated_features if active_contract.negotiated_features.present?
      end
    end

    # Disable all known premium features first to clean slate
    all_known_features = PlanFeatureLimit.feature_keys_for('enterprise')
    account.disable_features(*all_known_features)

    # Enable features for current plan
    account.enable_features(*enabled_features)
    account.enable_features(*manually_managed_features)

    # Map numeric limits keys to the Account schema properties
    account.limits = {
      'agents' => limits_hash['seats'],
      'contacts' => limits_hash['contacts'],
      'conversations' => limits_hash['conversations'],
      't3_subaccounts' => limits_hash['t3_subaccounts'],
      'automations' => limits_hash['automations'],
      'captain_documents' => limits_hash['captain_documents'],
      'captain_responses' => limits_hash['captain_responses'],
      'data_retention_months' => limits_hash['data_retention_months']
    }.compact

    account.save!
  end

  private

  def manually_managed_features
    @manually_managed_features ||= Internal::Accounts::InternalAttributesService.new(account).manually_managed_features
  end
end
