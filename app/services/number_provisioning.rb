module NumberProvisioning
  # India routes to Exotel, the United States routes to Telnyx. Any other
  # country is rejected before a provider is constructed.
  ROUTES = { 'IN' => ExotelProvider, 'US' => TelnyxProvider }.freeze
  ALLOWED_COUNTRIES = ROUTES.keys.freeze

  def self.for(account:, country_code:)
    code = country_code.to_s.upcase
    adapter_class = ROUTES[code]
    raise Provider::CountryNotAllowedError, code if adapter_class.nil?
    raise Provider::ProviderDisabledError, "#{adapter_class.name} is disabled" unless enabled?(adapter_class)

    adapter_class.new(account: account)
  end

  # Per-provider kill switches (CEO review finding 9A/3A), configurable at Super Admin >
  # Number Provisioning. Enabled state + fail-open/fail-closed defaults for an unseeded
  # config live in ProviderConfig::DEFINITIONS -- single source of truth, so this and the
  # admin page can't drift out of sync the way two separate default maps did on 2026-09-28.
  def self.enabled?(adapter_class)
    ProviderConfig.enabled_for?(adapter_class::PROVIDER_TYPE)
  end

  def self.table_name_prefix
    'number_provisioning_'
  end
end
