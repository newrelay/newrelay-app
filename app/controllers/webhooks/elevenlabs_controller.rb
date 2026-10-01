class Webhooks::ElevenlabsController < ActionController::API
  def process_payload
    account = Account.find_by(id: params[:account_id])
    return head :unauthorized if account.blank? || !valid_signature?(account)

    payload = JSON.parse(request.raw_post)
    Twilio::ElevenlabsCallLogService.new(account: account, payload: payload).perform
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def valid_signature?(account)
    secret = webhook_secret(account)
    timestamp, signatures = signature_parts
    return false if secret.blank? || timestamp.blank? || signatures.blank?
    return false if (Time.now.to_i - timestamp.to_i).abs > 30.minutes.to_i

    expected = OpenSSL::HMAC.hexdigest('SHA256', secret, "#{timestamp}.#{request.raw_post}")
    signatures.any? { |signature| secure_match?(expected, signature) }
  end

  def signature_parts
    header = request.headers['ElevenLabs-Signature'].to_s
    timestamp = header.split(',').find { |part| part.start_with?('t=') }&.delete_prefix('t=')
    signatures = header.split(',').select { |part| part.start_with?('v0=') }.map { |part| part.delete_prefix('v0=') }
    [timestamp, signatures]
  end

  def secure_match?(expected, signature)
    signature.bytesize == expected.bytesize && ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  def webhook_secret(account)
    Channel::TwilioSms.where(account_id: account.id).where.not(elevenlabs_webhook_secret: [nil, '']).pick(:elevenlabs_webhook_secret)
  end
end
