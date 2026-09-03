require 'rails_helper'

RSpec.describe CommentAutomation::MockAutoresponderStore do
  let(:account) { create(:account) }

  after { described_class.reset! }

  it 'returns no social accounts until an Instagram inbox exists' do
    store = described_class.new(account)

    expect(store.social_accounts).to eq([])
    expect(store.posts).to eq([])
    expect(store.dms).to eq([])
  end

  it 'serializes connected Instagram inboxes without mock mode' do
    with_modified_env(COMMENT_AUTOMATION_PROVIDER: '') do
      create(:channel_instagram, account: account)
      accounts = described_class.new(account).social_accounts

      expect(accounts.length).to eq 1
      expect(accounts.first[:platform]).to eq 'Instagram'
    end
  end

  it 'returns default settings and persists updates on the account' do
    store = described_class.new(account)

    expect(store.settings[:general][:globalAutomation]).to be true
    store.update_settings(general: { globalAutomation: false })
    described_class.reset!
    expect(described_class.new(account.reload).settings[:general][:globalAutomation]).to be false
  end

  context 'when COMMENT_AUTOMATION_PROVIDER=mock' do
    around do |example|
      with_modified_env(COMMENT_AUTOMATION_PROVIDER: 'mock') { example.run }
    end

    it 'updates a social account overlay and persists for later reads' do
      channel = create(:channel_instagram, account: account)
      store = described_class.new(account)
      updated = store.update_social_account(channel.inbox.id, assignedTeam: 'Support')

      expect(updated[:assignedTeam]).to eq 'Support'
      expect(described_class.new(account).social_accounts.first[:assignedTeam]).to eq 'Support'
    end

    it 'returns nil when updating a missing record' do
      expect(described_class.new(account).update_social_account('missing', assignedTeam: 'X')).to be_nil
    end

    it 'connects a mock Instagram inbox' do
      store = described_class.new(account)

      expect { store.connect('Instagram') }.to change { store.social_accounts.length }.from(0).to(1)
      expect(store.social_accounts.first[:platform]).to eq 'Instagram'
      expect(store.social_accounts.first[:name]).to eq 'Instagram Shop'
    end

    it 'raises when connecting Facebook' do
      expect { described_class.new(account).connect('Facebook') }.to raise_error(described_class::Error)
    end

    it 'raises when connecting while mock mode is off' do
      store = described_class.new(account)
      with_modified_env(COMMENT_AUTOMATION_PROVIDER: '') do
        expect { store.connect('Instagram') }.to raise_error(described_class::Error)
      end
    end

    it 'serializes campaigns as response-control posts' do
      inbox = create(:channel_instagram, account: account).inbox
      create(:comment_automation_campaign, account: account, inbox: inbox, name: 'Summer Sale')

      posts = described_class.new(account).posts
      expect(posts.length).to eq 1
      expect(posts.first[:title]).to eq 'Summer Sale'
      expect(posts.first[:inboxId]).to eq inbox.id.to_s
    end
  end
end
