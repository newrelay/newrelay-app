# frozen_string_literal: true

# =============================================================================
# ONE-OFF DEV UTILITY — enable ALL account features + put account on Enterprise
# =============================================================================
#
# Purpose:
#   Quickly unlocks every feature flag and Captain/LLM toggle for a single
#   local account so you can test Enterprise-gated UI without a real billing
#   subscription. NOT for use in production or staging.
#
# Usage (run from repo root):
#   eval "$(rbenv init -)"
#   bundle exec rails runner bin/enable_all_features_account.rb
#
# Or inline:
#   bundle exec rails runner "load Rails.root.join('bin/enable_all_features_account.rb')"
#
# Target account:
#   - Default: Account id 2  (most common local seed account)
#   - Variant: resolve via User id 2 → first AccountUser membership (see USER_ID below)
#
# Related: bin/enable_features.rb  (installation-wide + ALL accounts)
#
# DO NOT run against production.
# =============================================================================

raise 'Refusing to run in production' if Rails.env.production?

# --- Target selection -------------------------------------------------------
# Primary path: Account id 2
ACCOUNT_ID = 2

# Variant: resolve via User id 2 → first account membership.
# Set to an integer (e.g. 2) to use this instead of ACCOUNT_ID.
USER_ID = nil
# USER_ID = 2

account = if USER_ID
            user = User.find(USER_ID)
            user.accounts.first || raise("User #{USER_ID} has no account memberships")
          else
            Account.find(ACCOUNT_ID)
          end

# --- Helpers ----------------------------------------------------------------
def feature_count(acc)
  acc.enabled_features.size
end

def captain_enabled_count(acc)
  (acc.captain_features || {}).count { |_k, v| v == true }
end

def summarize(label, acc)
  attrs = acc.custom_attributes || {}
  sub = acc.subscription
  puts "--- #{label} ---"
  puts "  account_id:            #{acc.id} (#{acc.name})"
  puts "  plan_name:             #{attrs['plan_name'].inspect}"
  puts "  subscription_status:   #{attrs['subscription_status'].inspect}"
  puts "  subscribed_quantity:   #{attrs['subscribed_quantity'].inspect}"
  puts "  subscription.record:   #{sub ? "#{sub.plan_name}/#{sub.status}" : 'nil'}"
  puts "  enabled_features:      #{feature_count(acc)} / #{Featurable::FEATURE_LIST.size}"
  puts "  captain_features_on:   #{captain_enabled_count(acc)} / #{Llm::Models.feature_keys.size}"
  puts "  limits:                #{acc.limits.inspect}"
end

summarize('BEFORE', account)

# --- 1) Mark installation pricing as Enterprise (self-hosted path) ----------
# Mirrors bin/enable_features.rb. Cloud UI still keys off account plan_name.
config_plan = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
config_plan.value = 'enterprise'
config_plan.save!

config_qty = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
config_qty.value = 1000
config_qty.save!
GlobalConfig.clear_cache

# --- 2) Put account on Enterprise plan (same shape as bypass_plan) ----------
# Cloud UI reads custom_attributes['plan_name'] — must be capitalized "Enterprise".
subscribed_quantity = [(account.custom_attributes || {})['subscribed_quantity'].to_i, 1000].max

account.update!(
  custom_attributes: (account.custom_attributes || {}).merge(
    'plan_name' => 'Enterprise',
    'subscription_status' => 'active',
    'subscribed_quantity' => subscribed_quantity
  )
)

subscription = account.subscription || account.build_subscription
subscription.assign_attributes(
  plan_name: 'Enterprise',
  status: 'active',
  relationship_type: 'platform',
  payment_provider: subscription.payment_provider.presence || 'stripe',
  subscribed_quantity: subscribed_quantity,
  current_period_start: Time.current,
  current_period_end: 10.years.from_now
)
subscription.save!

# Apply enterprise matrix limits/features if PlanFeatureLimit rows exist.
# No-op when the enterprise matrix was never seeded (common in local).
if defined?(Enterprise::Billing::ReconcilePlanFeaturesService)
  Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
  account.reload
end

# --- 3) Enable ALL Featurable features (above any plan matrix) --------------
feature_names = Featurable::FEATURE_LIST.pluck('name')
account.enable_features!(*feature_names)

# --- 4) Enable ALL Captain / LLM feature toggles ----------------------------
ai_features = Llm::Models.feature_keys.index_with { true }
account.update!(captain_features: ai_features)

# --- 5) Generous local limits ----------------------------------------------
max = ChatwootApp.max_limit
account.update!(
  limits: (account.limits || {}).merge(
    'agents' => max,
    'inboxes' => max,
    'contacts' => max,
    'conversations' => max,
    't3_subaccounts' => max,
    'automations' => max,
    'captain_documents' => max,
    'captain_responses' => max
    # omit data_retention_months → unlimited retention for local Enterprise use
  )
)

account.reload
summarize('AFTER', account)

puts
puts "Done. Account #{account.id} is on Enterprise with all features + captain toggles enabled."
puts 'Reload the dashboard (hard refresh) to see plan/features unlock.'
