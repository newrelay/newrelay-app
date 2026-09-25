# Every number-provider adapter implements this, so callers depend on the
# interface, not on Telnyx::* or Exotel::* directly. Two providers exist
# because neither covers both regions alone: Exotel has no SIP trunk for
# US numbers, Telnyx has no SMS capability on India numbers.
module NumberProvisioning::Provider
  def search(country_code:, type: nil)
    raise NotImplementedError
  end

  def order(phone_number:)
    raise NotImplementedError
  end
end
