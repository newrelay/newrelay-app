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

  def search(country_code:, type: nil)
    raise NotImplementedError
  end

  def order(phone_number:)
    raise NotImplementedError
  end

  def status(provider_order_id:)
    raise NotImplementedError
  end

  private

  def assert_success!(response, action)
    return if response.success?

    raise RequestError.new(action, status: response.code, body: response.body)
  end
end
