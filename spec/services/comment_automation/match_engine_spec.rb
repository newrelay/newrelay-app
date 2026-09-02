require 'rails_helper'

RSpec.describe CommentAutomation::MatchEngine do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account, instagram_id: 'ig-account-1') }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox, post_id: 'media-1') }

  def comment(text:, from_id: 'commenter-1')
    { text: text, from: { id: from_id } }
  end

  it 'returns the trigger whose keyword is contained in the comment text' do
    trigger = create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'price', match_type: :contains)

    result = described_class.new(campaign: campaign, comment: comment(text: 'what is the price?')).match

    expect(result).to eq trigger
  end

  it 'returns nil when no trigger keyword matches' do
    create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'price', match_type: :contains)

    result = described_class.new(campaign: campaign, comment: comment(text: 'nice post!')).match

    expect(result).to be_nil
  end

  it 'requires an exact match for exact match_type triggers' do
    create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'info', match_type: :exact)

    result = described_class.new(campaign: campaign, comment: comment(text: 'send me info please')).match

    expect(result).to be_nil
  end

  it 'matches case-insensitively' do
    trigger = create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'PRICE', match_type: :contains)

    result = described_class.new(campaign: campaign, comment: comment(text: 'what is the price?')).match

    expect(result).to eq trigger
  end

  it 'excludes comments made by the connected account itself' do
    create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'price', match_type: :contains)

    result = described_class.new(campaign: campaign, comment: comment(text: 'the price is $10', from_id: 'ig-account-1')).match

    expect(result).to be_nil
  end
end
