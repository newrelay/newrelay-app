## Class to seed the PlanFeatureLimit matrix (boolean features + numeric resource
## limits, including Captain AI credits) for the self-serve cloud plans.
##
## Enterprise is intentionally excluded — it isn't sold off a fixed matrix, it's
## negotiated per-account via EnterpriseContract (see enterprise_contract.rb).
############################################################
### Usage #####
#
#   Seeders::PlanFeatureLimitSeeder.new.perform!
#
############################################################
class Seeders::PlanFeatureLimitSeeder
  PLAN_KEYS = %w[hobby standard business].freeze

  # Numeric resource quotas per plan, keyed by PlanFeatureLimit::RESOURCE_LIMIT_KEYS.
  # captain_documents / captain_responses are the Captain AI credit allowance for the plan.
  # data_retention_months: how long conversations/messages/attachments are kept before
  # Internal::PurgeExpiredConversationsJob permanently deletes them (see that job for enforcement).
  RESOURCE_LIMITS = {
    'hobby' => {
      'seats' => 1, 'contacts' => 500, 'conversations' => 200, 't3_subaccounts' => 0, 'automations' => 3,
      'captain_documents' => 0, 'captain_responses' => 0, 'data_retention_months' => 1
    },
    'standard' => {
      'seats' => 5, 'contacts' => 5000, 'conversations' => 2000, 't3_subaccounts' => 3, 'automations' => 15,
      'captain_documents' => 0, 'captain_responses' => 0, 'data_retention_months' => 6
    },
    'business' => {
      'seats' => 20, 'contacts' => 50_000, 'conversations' => 20_000, 't3_subaccounts' => 25, 'automations' => 100,
      'captain_documents' => 200, 'captain_responses' => 300, 'data_retention_months' => 12
    }
  }.freeze

  # Boolean features gated to Business/Enterprise only; disabled on Hobby & Standard.
  PREMIUM_ONLY_FEATURES = %w[
    disable_branding audit_logs sla custom_roles captain_integration
    captain_v1_action_classifier help_center_embedding_search custom_tools
    advanced_search advanced_search_indexing saml captain_integration_v2
    captain_document_auto_sync white_labeling custom_domain reseller_dashboard
    api_access companies csat_review_notes conversation_required_attributes
    advanced_assignment channel_voice
  ].freeze

  def perform!
    PLAN_KEYS.each { |plan_key| seed_plan(plan_key) }
  end

  private

  def seed_plan(plan_key)
    seed_resource_limits(plan_key)
    seed_boolean_features(plan_key)
  end

  def seed_resource_limits(plan_key)
    RESOURCE_LIMITS.fetch(plan_key).each do |feature_key, limit_value|
      upsert(plan_key: plan_key, feature_key: feature_key, enabled: true, limit_value: limit_value)
    end
  end

  def seed_boolean_features(plan_key)
    all_feature_names.each do |feature_name|
      enabled = !(%w[hobby standard].include?(plan_key) && PREMIUM_ONLY_FEATURES.include?(feature_name))
      upsert(plan_key: plan_key, feature_key: feature_name, enabled: enabled, limit_value: nil)
    end
  end

  def all_feature_names
    @all_feature_names ||= YAML.load_file(Rails.root.join('config/features.yml'))
                               .reject { |f| f['deprecated'] }
                               .map { |f| f['name'] }
  end

  def upsert(plan_key:, feature_key:, enabled:, limit_value:)
    pfl = PlanFeatureLimit.find_or_initialize_by(plan_key: plan_key, feature_key: feature_key)
    pfl.enabled = enabled
    pfl.limit_value = limit_value
    pfl.save!
  end
end
