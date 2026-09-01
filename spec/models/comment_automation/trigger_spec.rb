require 'rails_helper'

RSpec.describe CommentAutomation::Trigger do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }

  it 'is valid with a keyword, match_type, public_replies, and dm_text_body' do
    trigger = described_class.new(
      campaign: campaign, account: account, keyword: 'price', match_type: :contains,
      public_replies: ['Thanks! Check your DMs.'], dm_text_body: 'Here is the info you asked for.'
    )
    expect(trigger).to be_valid
  end

  it 'is invalid without dm_text_body' do
    trigger = described_class.new(campaign: campaign, account: account, match_type: :contains, public_replies: ['hi'])
    expect(trigger).not_to be_valid
    expect(trigger.errors[:dm_text_body]).to be_present
  end

  it 'is invalid with an empty public_replies array' do
    trigger = described_class.new(campaign: campaign, account: account, match_type: :contains, dm_text_body: 'hi', public_replies: [])
    expect(trigger).not_to be_valid
    expect(trigger.errors[:public_replies]).to be_present
  end
end
