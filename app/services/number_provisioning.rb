module NumberProvisioning
  # India routes to Exotel, everything else routes to Telnyx -- confirmed on
  # a call with Exotel: SIP trunk works for India numbers, not for US.
  # Combined with the earlier finding that Telnyx has no SMS on India
  # numbers, neither provider covers both regions, so routing is per country.
  ROUTES = { 'IN' => ExotelProvider }.freeze
  DEFAULT = TelnyxProvider

  def self.for(account:, country_code:)
    adapter_class = ROUTES.fetch(country_code.to_s.upcase, DEFAULT)
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
