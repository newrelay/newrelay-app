# Development stand-in for Exotel's v2_beta HTTP API. Search, order, and
# status use the same shapes ExotelProvider already normalizes. Production
# never enables this. A purchased sid is derived from the phone number, so a
# process restart still reports that number as active.
class NumberProvisioning::DummyExotel
  PREFIX = 'dummy-exotel-'.freeze

  NUMBERS = [
    { 'phone_number' => '+919100000001', 'rental_price' => '999.000000', 'currency' => 'INR',
      'capabilities' => { 'sms' => false, 'voice' => true } },
    { 'phone_number' => '+919100000002', 'rental_price' => '499.000000', 'currency' => 'INR',
      'capabilities' => { 'sms' => false, 'voice' => true } },
    { 'phone_number' => '+919100000003', 'rental_price' => '1499.000000', 'currency' => 'INR',
      'capabilities' => { 'sms' => false, 'voice' => true } }
  ].freeze

  DOCS_KEY = 'number_provisioning:dummy_exotel:docs:'.freeze

  class << self
    def enabled?
      return false if Rails.env.production?

      ActiveModel::Type::Boolean.new.cast(
        ENV.fetch('NUMBER_PROVISIONING_EXOTEL_DUMMY', Rails.env.development?.to_s)
      )
    end

    def search
      NUMBERS.map(&:dup)
    end

    def order(phone_number)
      sid = sid_for(phone_number)
      {
        'sid' => sid,
        'id' => sid,
        'phone_number' => phone_number,
        'rental_price' => '999.000000',
        'currency' => 'INR',
        'capabilities' => { 'sms' => false, 'voice' => true }
      }
    end

    def status(provider_order_id)
      return { 'status' => 'failed' } unless provider_order_id.to_s.start_with?(PREFIX)
      return { 'status' => 'active' } if documents_submitted?(provider_order_id)

      { 'status' => 'requirements_pending' }
    end

    def mark_documents_submitted(provider_order_id)
      Redis::Alfred.set("#{DOCS_KEY}#{provider_order_id}", '1')
    end

    def documents_submitted?(provider_order_id)
      Redis::Alfred.get("#{DOCS_KEY}#{provider_order_id}").present?
    end

    def release(provider_order_id)
      provider_order_id.to_s.start_with?(PREFIX)
    end

    def sid_for(phone_number)
      "#{PREFIX}#{phone_number.to_s.delete('+')}"
    end
  end
end
