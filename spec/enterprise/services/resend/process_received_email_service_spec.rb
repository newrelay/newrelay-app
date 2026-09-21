require 'rails_helper'

RSpec.describe Resend::ProcessReceivedEmailService do
  let(:email_id) { '4ef9a417-02e9-4d39-ad75-9611e0fcc33c' }
  let(:raw_url) { 'https://inbound.resend.com/receiving/raw/abc?Signature=sig' }
  let(:rfc822) do
    <<~MAIL
      From: customer@example.com
      To: reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@inbound.test
      Subject: Re: hello
      Message-ID: <msg-#{email_id}@example.com>
      MIME-Version: 1.0
      Content-Type: text/plain; charset=UTF-8

      Hello back
    MAIL
  end

  describe '#perform' do
    it 'skips when the Resend API key is missing' do
      result = described_class.new(email_id: email_id).perform

      expect(result).to eq(skipped: true)
    end

    context 'when the API key is present' do
      before do
        GlobalConfig.clear_cache
        create(:installation_config, name: 'RESEND_API_KEY', value: 're_test')
      end

      it 'downloads the raw email and creates an ActionMailbox inbound email' do
        stub_request(:get, "https://api.resend.com/emails/receiving/#{email_id}")
          .to_return(
            status: 200,
            body: { 'id' => email_id, 'raw' => { 'download_url' => raw_url } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        stub_request(:get, raw_url).to_return(status: 200, body: rfc822)

        expect { described_class.new(email_id: email_id).perform }
          .to change(ActionMailbox::InboundEmail, :count).by(1)
          .and change(ProcessedWebhookEvent, :count).by(1)

        expect(ProcessedWebhookEvent.last.stripe_event_id).to eq("resend_inbound_#{email_id}")
      end

      it 'raises when Resend returns an error' do
        stub_request(:get, "https://api.resend.com/emails/receiving/#{email_id}")
          .to_return(
            status: 404,
            body: { 'message' => 'Email not found' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { described_class.new(email_id: email_id).perform }
          .to raise_error(Resend::ProcessReceivedEmailService::Error, 'Email not found')
      end
    end
  end
end
