require 'rails_helper'

describe EmailTemplates::PreviewService do
  describe '#perform' do
    it 'fills liquid variables and wraps content in the mailer layout' do
      entry = EmailTemplates::Catalog.find!('mailers--agent_notifications--conversation_notifications_mailer--conversation_creation')
      html = described_class.new(entry: entry, body: entry.file_body).perform

      expect(html).to include('email-container')
      expect(html).to include('Alex Rivera')
      expect(html).to include('Jordan Lee')
      expect(html).to include('#42')
    end

    it 'injects sample inner content when previewing the layout' do
      entry = EmailTemplates::Catalog.find!('layouts--mailer--base')
      html = described_class.new(entry: entry, body: entry.file_body).perform

      expect(html).to include('sample body content')
      expect(html).to include('email-container')
      expect(html).to include('/brand-assets/logo.svg')
    end
  end
end
