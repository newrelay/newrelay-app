module NumberProvisioning
  # India routes to Exotel, everything else routes to Telnyx -- confirmed on
  # a call with Exotel: SIP trunk works for India numbers, not for US.
  # Combined with the earlier finding that Telnyx has no SMS on India
  # numbers, neither provider covers both regions, so routing is per country.
  ROUTES = { 'IN' => ExotelProvider }.freeze
  DEFAULT = TelnyxProvider

  def self.for(account:, country_code:)
    adapter_class = ROUTES.fetch(country_code.to_s.upcase, DEFAULT)
    adapter_class.new(account: account)
  end

  def self.table_name_prefix
    'number_provisioning_'
  end
end
