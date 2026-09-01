require 'rails_helper'

RSpec.describe CommentAutomation::MessageLog do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }
  let(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account) }

  it 'is valid with a trigger, account, inbox, comment_id, and commenter_id' do
    log = described_class.new(trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1', commenter_id: 'commenter-1')
    expect(log).to be_valid
  end

  it 'defaults status to pending' do
    log = described_class.create!(trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1', commenter_id: 'commenter-1')
    expect(log.status).to eq 'pending'
  end

  it 'rejects a duplicate comment_id within the same inbox at the database level' do
    described_class.create!(trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1', commenter_id: 'commenter-1')
    duplicate = described_class.new(trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1', commenter_id: 'commenter-2')

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
