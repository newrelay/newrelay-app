require 'rails_helper'

RSpec.describe CommentAutomation::MockAutoresponderStore do
  let(:account) { create(:account) }

  after { described_class.reset! }

  it 'returns empty collections when mock mode is off' do
    with_modified_env(COMMENT_AUTOMATION_PROVIDER: '') do
      store = described_class.new(account)
      expect(store.social_accounts).to eq([])
      expect(store.posts).to eq([])
    end
  end

  context 'when COMMENT_AUTOMATION_PROVIDER=mock' do
    around do |example|
      with_modified_env(COMMENT_AUTOMATION_PROVIDER: 'mock') { example.run }
    end

    it 'returns seeded social accounts and response controls' do
      store = described_class.new(account)

      expect(store.social_accounts.length).to eq 4
      expect(store.social_accounts.first[:handle]).to eq '@newrelay'
      expect(store.posts.length).to eq 5
      expect(store.dms.length).to eq 4
      expect(store.team_members.length).to eq 6
    end

    it 'updates a social account and persists for later reads' do
      store = described_class.new(account)
      updated = store.update_social_account('acc-1', assignedTeam: 'Support Team')

      expect(updated[:assignedTeam]).to eq 'Support Team'
      expect(described_class.new(account).social_accounts.first[:assignedTeam]).to eq 'Support Team'
    end

    it 'returns nil when updating a missing record' do
      expect(described_class.new(account).update_social_account('missing', assignedTeam: 'X')).to be_nil
    end

    it 'connects a new Instagram account' do
      store = described_class.new(account)

      expect { store.connect('Instagram') }.to change { store.social_accounts.length }.by(1)
      expect(store.social_accounts.last[:platform]).to eq 'Instagram'
    end

    it 'raises when connecting while mock mode is off' do
      store = described_class.new(account)
      with_modified_env(COMMENT_AUTOMATION_PROVIDER: '') do
        expect { store.connect('Instagram') }.to raise_error(described_class::Error)
      end
    end
  end
end
