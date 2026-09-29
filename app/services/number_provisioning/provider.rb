# Every number-provider adapter implements this, so callers depend on the
# interface, not on Telnyx::* or Exotel::* directly. Two providers exist
# because neither covers both regions alone: Exotel has no SIP trunk for
# US numbers, Telnyx has no SMS capability on India numbers.
module NumberProvisioning::Provider
  # Carries the real HTTP status/body instead of a bare string, so callers can
  # distinguish e.g. a 409 (number likely taken by another buyer) from a 5xx/
  # network failure without guessing at a per-provider error taxonomy that
  # hasn't been confirmed against real API responses yet.
  class RequestError < StandardError
    attr_reader :status, :body

    def initialize(action, status:, body:)
      @status = status
      @body = body
      super("#{action} failed (#{status}): #{body}")
    end
  end

  # Raised when NumberProvisioning.for resolves to a provider whose
  # NUMBER_PROVISIONING_*_ENABLED flag is off.
  class ProviderDisabledError < StandardError; end

  class CountryNotAllowedError < StandardError; end

  def search(country_code:, type: nil)
    raise NotImplementedError
  end

  def order(phone_number:)
    raise NotImplementedError
  end

  def status(provider_order_id:)
    raise NotImplementedError
  end

  # True only when the provider accepted the release. Missing or failed calls
  # return false so the order stays billing_failed.
  def release(phone_number:, provider_order_id:)
    false
  end

  private

  def assert_success!(response, action)
    return if response.success?

    raise RequestError.new(action, status: response.code, body: response.body)
  end

  # Providers quote a monthly price as a decimal string in a major unit
  # (Telnyx "1.00" USD, Exotel "999.000000" INR). Normalize to integer minor
  # units so billing never does float math on money. Unparseable/blank -> nil,
  # which downstream treats as "cost unknown" (no charge) rather than a fake 0.
  def price_to_cents(value)
    return nil if value.blank?

    (BigDecimal(value.to_s) * 100).round.to_i
  rescue ArgumentError
    nil
  end
end
