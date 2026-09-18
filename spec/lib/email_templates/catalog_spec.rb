require 'rails_helper'

describe EmailTemplates::Catalog do
  describe '.entries' do
    it 'includes the shared mailer layout and a liquid notification' do
      keys = described_class.entries.map(&:key)

      expect(keys).to include('layouts--mailer--base')
      expect(keys).to include('mailers--agent_notifications--conversation_notifications_mailer--conversation_creation')
    end

    it 'marks liquid templates editable and erb templates read-only' do
      layout = described_class.entries.find { |entry| entry.key == 'layouts--mailer--base' }
      confirmation = described_class.entries.find { |entry| entry.key == 'devise--mailer--confirmation_instructions' }

      expect(layout).to have_attributes(format: 'liquid', editable: true, template_type: 'layout', category: 'Layout')
      expect(confirmation).to have_attributes(format: 'erb', editable: false, category: 'Authentication')
    end
  end

  describe '.find!' do
    it 'returns the matching entry' do
      entry = described_class.find!('layouts--mailer--base')

      expect(entry.title).to eq('Base')
      expect(entry.file_body).to include('email-container')
    end

    it 'raises when the key is unknown' do
      expect { described_class.find!('missing-template') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
