require 'rails_helper'

RSpec.describe CommentAutomation::Campaign do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  it 'is valid with account, inbox, name, and post_id' do
    campaign = described_class.new(account: account, inbox: inbox, name: 'Launch Post', post_id: '17895695668004550')
    expect(campaign).to be_valid
  end

  it 'is invalid without a post_id' do
    campaign = described_class.new(account: account, inbox: inbox, name: 'Launch Post')
    expect(campaign).not_to be_valid
    expect(campaign.errors[:post_id]).to be_present
  end

  it 'defaults is_active to true' do
    campaign = described_class.create!(account: account, inbox: inbox, name: 'Launch Post', post_id: '17895695668004550')
    expect(campaign.is_active).to be true
  end

  it 'normalizes an Instagram permalink to the short media id' do
    campaign = described_class.create!(
      account: account, inbox: inbox, name: 'Launch Post',
      post_id: 'https://www.instagram.com/p/mock-summer-sale/?igsh=abc'
    )
    expect(campaign.post_id).to eq 'mock-summer-sale'
  end
end
