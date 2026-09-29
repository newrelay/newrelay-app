# Super Admin-facing view of each provider's platform credentials, currency,
# margin %, and enabled state -- all InstallationConfig-backed, same mechanism
# already used for TELNYX_RESELLER_API_KEY etc. (see agent decision log,
# 2026-09-28: modeled on Enterprise::Billing::PaymentGatewayRegistry's shape,
# without its country-routing logic, which doesn't apply here).
class NumberProvisioning::ProviderConfig
  class ValidationError < StandardError; end

  # default_enabled/default_currency mirror config/installation_config.yml's own `value:`
  # defaults for these keys. Duplicated on purpose, not read from the yml at runtime: until
  # ConfigLoader#process (run from db:seed) has synced a new key into InstallationConfig,
  # GlobalConfig.get_value returns nil for it -- without a fallback here, this admin page
  # would show "disabled" / a blank currency for a provider the running code actually
  # treats as enabled with a real default currency, which is worse than a small duplication.
  DEFINITIONS = {
    'telnyx' => {
      label: 'Telnyx',
      enabled_key: 'NUMBER_PROVISIONING_TELNYX_ENABLED',
      default_enabled: true,
      currency_key: 'NUMBER_PROVISIONING_TELNYX_CURRENCY',
      default_currency: 'USD',
      margin_key: 'NUMBER_PROVISIONING_TELNYX_MARGIN_PERCENT',
      key_fields: [
        { name: 'TELNYX_RESELLER_API_KEY', label: 'API Key' }
      ]
    },
    'exotel' => {
      label: 'Exotel',
      enabled_key: 'NUMBER_PROVISIONING_EXOTEL_ENABLED',
      default_enabled: false,
      currency_key: 'NUMBER_PROVISIONING_EXOTEL_CURRENCY',
      default_currency: 'INR',
      margin_key: 'NUMBER_PROVISIONING_EXOTEL_MARGIN_PERCENT',
      key_fields: [
        { name: 'EXOTEL_RESELLER_ACCOUNT_SID', label: 'Account SID' },
        { name: 'EXOTEL_RESELLER_API_KEY', label: 'API Key' },
        { name: 'EXOTEL_RESELLER_API_TOKEN', label: 'API Token' }
      ]
    }
  }.freeze

  class << self
    def admin_view
      DEFINITIONS.map { |id, definition| provider_row(id, definition) }
    end

    # Single source of truth for "is this provider allowed to route real traffic" --
    # NumberProvisioning.for delegates here instead of keeping its own copy of the
    # enabled-flag lookup and the fail-open/fail-closed defaults.
    def enabled_for?(id)
      enabled?(DEFINITIONS.fetch(id))
    end

    def all_config_keys
      DEFINITIONS.flat_map do |_id, definition|
        [
          definition[:enabled_key],
          definition[:currency_key],
          definition[:margin_key],
          *definition[:key_fields].map { |f| f[:name] }
        ]
      end
    end

    def clear_cache
      all_config_keys.each { |key| GlobalConfig.clear_key(key) }
    end

    # providers_param is an ActionController::Parameters, which already resolves string
    # and symbol keys interchangeably (like PaymentGatewayRegistry.save! relies on) --
    # no .with_indifferent_access, that method doesn't exist on this class.
    def save!(providers_param)
      params = providers_param || {}

      DEFINITIONS.each do |id, definition|
        row = params[id] || {}
        save_margin!(definition[:margin_key], row[:margin_percent])
        save_scalar!(definition[:currency_key], row[:currency].to_s.strip.upcase) if row[:currency].present?
        save_scalar!(definition[:enabled_key], row[:enabled] == '1')

        definition[:key_fields].each do |field|
          value = row.dig(:keys, field[:name])
          save_scalar!(field[:name], value) if value.present?
        end
      end
    end

    private

    def provider_row(id, definition)
      {
        'id' => id,
        'label' => definition[:label],
        'enabled' => enabled?(definition),
        'currency' => GlobalConfig.get_value(definition[:currency_key]) || definition[:default_currency],
        'margin_percent' => GlobalConfig.get_value(definition[:margin_key]) || '0',
        'key_fields' => definition[:key_fields].map { |field| key_field_row(field) }
      }
    end

    def key_field_row(field)
      { 'name' => field[:name], 'label' => field[:label], 'value' => GlobalConfig.get_value(field[:name]) }
    end

    def enabled?(definition)
      value = GlobalConfig.get_value(definition[:enabled_key])
      return definition[:default_enabled] if value.nil?

      ActiveRecord::Type::Boolean.new.cast(value)
    end

    def save_margin!(key, raw_value)
      return if raw_value.blank?

      parsed = Float(raw_value, exception: false)
      raise ValidationError, "Margin must be a number between 0 and 100 (got #{raw_value.inspect})" if parsed.nil? || !(0..100).cover?(parsed)

      save_scalar!(key, parsed.to_s)
    end

    def save_scalar!(key, value)
      config = InstallationConfig.find_or_initialize_by(name: key)
      config.value = value
      config.save!
    end
  end
end
