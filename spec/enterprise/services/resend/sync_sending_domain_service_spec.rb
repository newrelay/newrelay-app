require 'rails_helper'

RSpec.describe Resend::SyncSendingDomainService do
  let(:account) { create(:account) }
  let(:domain_id) { 'dom_123' }
  let(:records) do
    [
      { 'record' => 'DKIM', 'name' => 'resend._domainkey', 'type' => 'TXT', 'value' => 'p=abc', 'status' => 'not_started' }
    ]
  end
  let(:domain_payload) do
    {
      'id' => domain_id,
      'name' => 'app.child.test',
      'status' => 'not_started',
      'records' => records
    }
  end

  before do
    account.enable_features!(:custom_domain)
    account.update!(custom_domain: 'app.child.test')
  end

  describe '#perform' do
    it 'skips when the Resend API key is missing' do
      result = described_class.new(account: account).perform

      expect(result).to eq(skipped: true)
    end

    context 'when the API key is present' do
      before do
        GlobalConfig.clear_cache
        create(:installation_config, name: 'RESEND_API_KEY', value: 're_test')
      end

      it 'creates the domain, verifies it, and stores sending records' do
        stub_request(:get, 'https://api.resend.com/domains')
          .to_return(status: 200, body: { 'data' => [] }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, 'https://api.resend.com/domains')
          .with(
            headers: { 'Authorization' => 'Bearer re_test', 'Content-Type' => 'application/json' },
            body: { name: 'app.child.test' }.to_json
          )
          .to_return(status: 200, body: domain_payload.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, "https://api.resend.com/domains/#{domain_id}/verify")
          .to_return(status: 200, body: { 'object' => 'domain', 'id' => domain_id }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "https://api.resend.com/domains/#{domain_id}")
          .to_return(
            status: 200,
            body: domain_payload.merge('status' => 'verified').to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = described_class.new(account: account).perform

        expect(result[:errors]).to be_nil
        expect(account.reload.ssl_settings['resend_domain_id']).to eq(domain_id)
        expect(account.ssl_settings['resend_status']).to eq('verified')
        expect(account.ssl_settings['resend_from_email']).to eq('noreply@app.child.test')
        expect(account.ssl_settings['resend_records']).to eq(records)
      end

      it 'returns an error when create fails' do
        stub_request(:get, 'https://api.resend.com/domains')
          .to_return(status: 200, body: { 'data' => [] }.to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, 'https://api.resend.com/domains')
          .to_return(
            status: 422,
            body: { 'message' => 'Invalid domain' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = described_class.new(account: account).perform

        expect(result[:errors]).to eq(['Invalid domain'])
      end
    end
  end
end
