class Enterprise::Billing::CloudPlans
  CONFIG_NAME = 'CHATWOOT_CLOUD_PLANS'.freeze
  ENTERPRISE_PLAN = 'Enterprise'.freeze

  class << self
    def all
      InstallationConfig.find_by(name: CONFIG_NAME)&.value || []
    end

    def find(name)
      all.find { |plan| plan['name'] == name }
    end

    def enabled?(name)
      plan = find(name)
      plan.present? && plan['enabled'] != false
    end

    def purchasable_names
      all.filter_map do |plan|
        name = plan['name'].presence
        next if name.blank?
        next if plan['enabled'] == false
        next if name == ENTERPRISE_PLAN

        name
      end
    end

    def purchasable?(name)
      purchasable_names.include?(name)
    end

    def public_catalog
      all.map { |plan| plan.slice('name', 'price_per_agent', 'enabled', 'gateway_prices') }
    end

    def price_for(name, provider)
      plan = find(name)
      return 0.0 if plan.blank?

      if plan['gateway_prices'].present? && plan['gateway_prices'][provider.to_s].present?
        plan['gateway_prices'][provider.to_s]['amount'].to_f
      else
        plan['price_per_agent'].to_f
      end
    end
  end
end
