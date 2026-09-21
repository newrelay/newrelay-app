class Resend::WebhookVerifier
  TOLERANCE = 5.minutes

  def self.valid?(payload:, id:, timestamp:, signatures:, secret:)
    return false if [payload, id, timestamp, signatures, secret].any?(&:blank?)
    return false unless timestamp_fresh?(timestamp)

    expected = expected_signature(payload: payload, id: id, timestamp: timestamp, secret: secret)
    signatures.to_s.split.any? { |part| matching_v1?(part, expected) }
  end

  def self.timestamp_fresh?(timestamp)
    ts = timestamp.to_i
    now = Time.now.to_i
    ts.between?(now - TOLERANCE.to_i, now + TOLERANCE.to_i)
  end

  def self.expected_signature(payload:, id:, timestamp:, secret:)
    secret_bytes = Base64.decode64(secret.to_s.delete_prefix('whsec_'))
    digest = OpenSSL::HMAC.digest('SHA256', secret_bytes, "#{id}.#{timestamp}.#{payload}")
    Base64.strict_encode64(digest)
  end

  def self.matching_v1?(part, expected)
    version, signature = part.split(',', 2)
    return false unless version == 'v1' && signature.present?
    return false unless signature.bytesize == expected.bytesize

    ActiveSupport::SecurityUtils.secure_compare(signature, expected)
  end
  private_class_method :timestamp_fresh?, :expected_signature, :matching_v1?
end
