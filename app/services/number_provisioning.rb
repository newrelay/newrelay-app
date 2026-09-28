module NumberProvisioning
  # India routes to Exotel, everything else routes to Telnyx -- confirmed on
  # a call with Exotel: SIP trunk works for India numbers, not for US.
  # Combined with the earlier finding that Telnyx has no SMS on India
  # numbers, neither provider covers both regions, so routing is per country.
  ROUTES = { 'IN' => ExotelProvider }.freeze
  DEFAULT = TelnyxProvider

  # Per-provider kill switches (CEO review finding 9A/3A). Exotel defaults off
  # in config/installation_config.yml: its credential model (customer's own
  # Hook, not a platform key) is still an open decision -- see
  # docs/solution-notes/adr-exotel-india-sms-provider.md -- so it must not
  # route real traffic until that's resolved, independent of Telnyx.
  ENABLED_CONFIG_KEYS = {
    TelnyxProvider => 'NUMBER_PROVISIONING_TELNYX_ENABLED',
    ExotelProvider => 'NUMBER_PROVISIONING_EXOTEL_ENABLED'
  }.freeze

  # What "not yet configured" should mean per provider, i.e. GlobalConfig.get_value
  # returning nil because the InstallationConfig row hasn't been created yet (that
  # only happens via ConfigLoader#process, run from db:seed -- a separate deploy step
  # from the code push). Without this, nil casts to false for BOTH providers, which
  # would silently disable Telnyx -- the one that already works today -- the moment
  # this code ships ahead of the seed step. Fail-open for Telnyx, fail-closed for
  # Exotel (its credential model is still an open decision).
  DEFAULT_ENABLED_WHEN_UNSET = {
    TelnyxProvider => true,
    ExotelProvider => false
  }.freeze

  def self.for(account:, country_code:)
    adapter_class = ROUTES.fetch(country_code.to_s.upcase, DEFAULT)
    raise Provider::ProviderDisabledError, "#{adapter_class.name} is disabled" unless enabled?(adapter_class)

    adapter_class.new(account: account)
  end

  def self.enabled?(adapter_class)
    value = GlobalConfig.get_value(ENABLED_CONFIG_KEYS.fetch(adapter_class))
    return DEFAULT_ENABLED_WHEN_UNSET.fetch(adapter_class) if value.nil?

    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def self.table_name_prefix
    'number_provisioning_'
  end
end
