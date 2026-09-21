require 'rails_helper'

RSpec.describe Resend::WebhookVerifier do
  let(:secret) { "whsec_#{Base64.strict_encode64('test-secret')}" }
  let(:payload) { '{"type":"email.received"}' }
  let(:id) { 'msg_123' }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:signature) do
    secret_bytes = Base64.decode64(secret.delete_prefix('whsec_'))
    digest = OpenSSL::HMAC.digest('SHA256', secret_bytes, "#{id}.#{timestamp}.#{payload}")
    "v1,#{Base64.strict_encode64(digest)}"
  end

  it 'accepts a matching Svix signature' do
    expect(
      described_class.valid?(
        payload: payload,
        id: id,
        timestamp: timestamp,
        signatures: signature,
        secret: secret
      )
    ).to be(true)
  end

  it 'rejects a bad signature' do
    expect(
      described_class.valid?(
        payload: payload,
        id: id,
        timestamp: timestamp,
        signatures: 'v1,aaaa',
        secret: secret
      )
    ).to be(false)
  end
end
