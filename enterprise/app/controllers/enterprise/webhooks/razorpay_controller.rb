class Enterprise::Webhooks::RazorpayController < ActionController::API
  def process_payload
    payload = request.body.read
    signature = request.headers['X-Razorpay-Signature']

    unless valid_signature?(payload, signature)
      head :bad_request
      return
    end

    event = JSON.parse(payload)
    Enterprise::Billing::HandleRazorpayEventService.new.perform(event: event)
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def valid_signature?(payload, signature)
    secret = ENV.fetch('RAZORPAY_WEBHOOK_SECRET', nil)
    return false if secret.blank? || signature.blank?

    expected = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end
end
