require "administrate/field/base"

class EnterpriseFeaturesField < Administrate::Field::Base
  # Hardcoded list of features from Chatwoot Cloud Plans
  AVAILABLE_FEATURES = [
    "advanced_assignment", "advanced_search", "advanced_search_indexing", "agent_bots", "agent_management", "api_access", "assignment_v2", "audit_logs", "auto_resolve_conversations", "campaigns", "canned_responses", "captain_document_auto_sync", "captain_integration", "captain_integration_v2", "captain_tasks", "captain_v1_action_classifier", "channel_email", "channel_facebook", "channel_instagram", "channel_tiktok", "channel_voice", "channel_website", "chatwoot_v4", "companies", "contact_chatwoot_support_team", "conversation_required_attributes", "conversation_unread_counts", "crm", "crm_integration", "crm_v2", "csat_review_notes", "custom_attributes", "custom_domain", "custom_reply_domain", "custom_reply_email", "custom_roles", "custom_tools", "disable_branding", "email_continuity_on_api_channel", "help_center", "help_center_embedding_search", "inbound_emails", "inbox_management", "inbox_view", "integrations", "ip_lookup", "labels", "linear_integration", "macros", "notion_integration", "reply_mailer_migration", "report_rollup", "reports", "reseller_dashboard", "saml", "search_with_gin", "shopify_integration", "sla", "team_management", "voice_recorder", "whatsapp_campaign", "white_labeling"
  ].freeze

  def self.permitted_attribute(attribute, _options = nil)
    { attribute => [] }
  end

  def available_features
    AVAILABLE_FEATURES
  end

  def enabled?(feature_key)
    (data || []).include?(feature_key)
  end

  def to_s
    data
  end
end
