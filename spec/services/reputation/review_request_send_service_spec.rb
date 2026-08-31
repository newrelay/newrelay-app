require 'rails_helper'

RSpec.describe Reputation::ReviewRequestSendService do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, :with_email, account: account) }
  let(:template) { create(:reputation_template, account: account) }
  let(:request_row) do
    create(:reputation_review_request, account: account, contact: contact, reputation_template: template, status: :sent)
  end

  describe '#deliver! in mock mode' do
    it 'keeps status sent, does not complete, and logs the public link' do
      service = described_class.new(account: account, template_id: template.id, contact_id: contact.id)

      with_modified_env(REPUTATION_GOOGLE_PROVIDER: 'mock', FRONTEND_URL: 'http://localhost:3000') do
        expect(Rails.logger).to receive(:info) do |msg|
          expect(msg).to include("/r/#{request_row.token}")
          expect(msg).to include("##{request_row.id}")
        end
        service.deliver!(request_row)
      end

      request_row.reload
      expect(request_row).to be_sent
      expect(request_row.completed_at).to be_nil
    end
  end
end
