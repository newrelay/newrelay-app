## Class to push local Stripe test-mode Price IDs into the CHATWOOT_CLOUD_PLANS
## InstallationConfig, so a fresh dev environment doesn't require manually
## pasting them into Super Admin > Plan Management every time the DB is reset.
##
## Price IDs are read from ENV (never hardcoded/committed), since every
## developer's Stripe test account has its own set of Price IDs. Set these in
## your local .env:
##
##   STRIPE_HOBBY_PRICE_ID=price_...
##   STRIPE_STANDARD_PRICE_ID=price_...
##   STRIPE_BUSINESS_PRICE_ID=price_...
##
## Plans with no matching ENV var are left untouched.
############################################################
### Usage #####
#
#   Seeders::StripePlanPriceSeeder.new.perform!
#
############################################################
class Seeders::StripePlanPriceSeeder
  PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  PLAN_ENV_KEYS = {
    'Hobby' => 'STRIPE_HOBBY_PRICE_ID',
    'Standard' => 'STRIPE_STANDARD_PRICE_ID',
    'Business' => 'STRIPE_BUSINESS_PRICE_ID'
  }.freeze

  DEFAULT_PLANS = [
    { 'name' => 'Hobby', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 0, 'enabled' => true },
    { 'name' => 'Standard', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 10, 'enabled' => true },
    { 'name' => 'Business', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 49, 'enabled' => true },
    { 'name' => 'Enterprise', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 0, 'enabled' => true }
  ].freeze

  def perform!
    return if price_ids_from_env.empty?

    config = InstallationConfig.find_or_initialize_by(name: PLANS_CONFIG)
    config.serialized_value = {}.with_indifferent_access if config.serialized_value.blank?
    config.value = DEFAULT_PLANS if config.value.blank?

    config.value = config.value.map do |plan|
      price_id = price_ids_from_env[plan['name']]
      price_id ? plan.merge('price_ids' => [price_id]) : plan
    end

    config.save!
  end

  private

  def price_ids_from_env
    @price_ids_from_env ||= PLAN_ENV_KEYS.filter_map do |plan_name, env_key|
      price_id = ENV.fetch(env_key, nil)
      [plan_name, price_id] if price_id.present?
    end.to_h
  end
end
