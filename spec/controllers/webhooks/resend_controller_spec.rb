require 'rails_helper'

RSpec.describe 'Webhooks::ResendController', type: :request do
  let(:secret) { "whsec_#{Base64.strict_encode64('test-secret')}" }
  let(:email_id) { '4ef9a417-02e9-4d39-ad75-9611e0fcc33c' }
  let(:payload) { { type: 'email.received', data: { email_id: email_id } }.to_json }
  let(:id) { 'msg_123' }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:signature) do
    secret_bytes = Base64.decode64(secret.delete_prefix('whsec_'))
    digest = OpenSSL::HMAC.digest('SHA256', secret_bytes, "#{id}.#{timestamp}.#{payload}")
    "v1,#{Base64.strict_encode64(digest)}"
  end

  def post_webhook(body:, sig: signature)
    post '/webhooks/resend',
         params: body,
         headers: {
           'CONTENT_TYPE' => 'application/json',
           'svix-id' => id,
           'svix-timestamp' => timestamp,
           'svix-signature' => sig
         }
  end

  before do
    GlobalConfig.clear_cache
    create(:installation_config, name: 'RESEND_WEBHOOK_SECRET', value: secret)
  end

  it 'enqueues processing for email.received' do
    expect(Resend::ProcessReceivedEmailJob).to receive(:perform_later).with(email_id)
    post_webhook(body: payload)
    expect(response).to have_http_status(:ok)
  end

  it 'returns unauthorized when the signature is invalid' do
    expect(Resend::ProcessReceivedEmailJob).not_to receive(:perform_later)
    post_webhook(body: payload, sig: 'v1,aaaa')
    expect(response).to have_http_status(:unauthorized)
  end
end
