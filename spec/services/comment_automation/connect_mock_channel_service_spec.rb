require 'rails_helper'

RSpec.describe CommentAutomation::ConnectMockChannelService do
  let(:account) { create(:account) }

  def perform(url: 'https://www.instagram.com/p/mock-summer-sale/', name: 'Instagram Shop')
    described_class.new(account: account, url: url, name: name).perform
  end

  it 'raises when mock mode is off' do
    with_modified_env(COMMENT_AUTOMATION_PROVIDER: '') do
      expect { perform }.to raise_error(described_class::Error)
    end
  end

  context 'when COMMENT_AUTOMATION_PROVIDER=mock' do
    around do |example|
      with_modified_env(COMMENT_AUTOMATION_PROVIDER: 'mock') { example.run }
    end

    it 'creates an Instagram inbox, campaign, and seeded activity without Graph HTTP' do
      inbox = perform

      expect(inbox.channel_type).to eq 'Channel::Instagram'
      expect(inbox.name).to eq 'Instagram Shop'
      expect(inbox.channel.instagram_id).to eq "mock-ig-#{account.id}"

      campaign = account.comment_automation_campaigns.find_by!(post_id: 'mock-summer-sale')
      expect(campaign.triggers.first.keyword).to eq 'PRICE'
      expect(account.comment_automation_message_logs.count).to eq 6
      expect(account.comment_automation_message_logs.engaged.count).to eq 3
      expect(account.comment_automation_templates.count).to eq 2
    end

    it 'parses a raw post id when the value is not a URL' do
      perform(url: 'media-123')

      expect(account.comment_automation_campaigns.find_by(post_id: 'media-123')).to be_present
    end

    it 'does not duplicate the inbox when connecting the same page again' do
      perform
      expect { perform }.not_to change(Inbox, :count)
    end
  end
end
