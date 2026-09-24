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
      expect(html).to include('New conversation')
    end

    it 'injects sample inner content when previewing the layout' do
      entry = EmailTemplates::Catalog.find!('layouts--mailer--base')
      html = described_class.new(entry: entry, body: entry.file_body).perform

      expect(html).to include('sample body content')
      expect(html).to include('email-container')
      expect(html).to include('/brand-assets/logo.svg')
      expect(html).to include('/email_icons/base.png')
    end

    it 'uses sample custom-brand values in the layout' do
      entry = EmailTemplates::Catalog.find!('layouts--mailer--base')
      html = described_class.new(entry: entry, body: entry.file_body, custom_brand: true).perform

      expect(html).to include('Acme')
      expect(html).to include('https://help.acme.test')
      expect(html).to include('/email_brand_icons/base.png')
      expect(html).to include('class="mascot-img"')
      expect(html).not_to include('/email_icons/base.png')
    end
  end
end
