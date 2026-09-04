require 'rails_helper'

RSpec.describe CommentAutomation::InboundCommentJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account, instagram_id: 'ig-account-1') }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox, post_id: 'media-1') }
  let!(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'price', match_type: :contains) }

  def comment_entry(comment_id: 'comment-1', text: 'how much is the price?', media_id: 'media-1')
    {
      'id' => 'ig-account-1',
      'changes' => [
        { 'field' => 'comments',
          'value' => { 'id' => comment_id, 'text' => text, 'from' => { 'id' => 'commenter-1' }, 'media' => { 'id' => media_id } } }
      ]
    }
  end

  it 'creates a pending message log for a matching comment' do
    expect { described_class.perform_now([comment_entry]) }.to change(CommentAutomation::MessageLog, :count).by(1)

    log = CommentAutomation::MessageLog.last
    expect(log.trigger).to eq trigger
    expect(log.comment_id).to eq 'comment-1'
    expect(log.commenter_id).to eq 'commenter-1'
    expect(log.status).to eq 'pending'
  end

  it 'enqueues CommentAutomation::PublicReplyJob for a matching comment' do
    expect { described_class.perform_now([comment_entry]) }.to have_enqueued_job(CommentAutomation::PublicReplyJob)
  end

  it 'does nothing for a comment with no matching trigger' do
    expect { described_class.perform_now([comment_entry(text: 'nice post!')]) }.not_to change(CommentAutomation::MessageLog, :count)
  end

  it 'does nothing for a comment on a campaign the account has no active campaign for' do
    expect { described_class.perform_now([comment_entry(media_id: 'some-other-post')]) }.not_to change(CommentAutomation::MessageLog, :count)
  end

  it 'uses the newest matching campaign when two automations watch the same post' do
    create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'price', match_type: :contains)
    newer = create(:comment_automation_campaign, account: account, inbox: inbox, post_id: 'media-1',
                                                 name: 'New mock-summer-sale rule')
    new_trigger = create(:comment_automation_trigger, campaign: newer, account: account, keyword: 'price',
                                                      match_type: :contains)

    described_class.perform_now([comment_entry(text: 'how much is the price?')])

    expect(CommentAutomation::MessageLog.last.trigger).to eq new_trigger
  end

  it 'matches a comment when the stored post_id is a permalink for the same media' do
    campaign.update_column(:post_id, 'https://www.instagram.com/p/mock-summer-sale/') # rubocop:disable Rails/SkipsModelValidations

    expect {
      described_class.perform_now([comment_entry(media_id: 'mock-summer-sale', text: 'how much is the price?')])
    }.to change(CommentAutomation::MessageLog, :count).by(1)
  end

  it 'ignores a campaign on a different inbox that happens to share the post_id' do
    other_inbox = create(:channel_instagram, account: account, instagram_id: 'ig-account-2').inbox
    other_campaign = create(:comment_automation_campaign, account: account, inbox: other_inbox, post_id: 'media-2')
    create(:comment_automation_trigger, campaign: other_campaign, account: account, keyword: 'price', match_type: :contains)
    campaign.update!(post_id: 'media-2')

    expect { described_class.perform_now([comment_entry(media_id: 'media-2')]) }.to change(CommentAutomation::MessageLog, :count).by(1)
    expect(CommentAutomation::MessageLog.last.trigger).to eq trigger
  end

  it 'does nothing for a comment missing a commenter id' do
    malformed = comment_entry
    malformed['changes'][0]['value'].delete('from')

    expect { described_class.perform_now([malformed]) }.not_to change(CommentAutomation::MessageLog, :count)
  end

  it 'does not create a second log or enqueue a second reply for a duplicate comment_id' do
    described_class.perform_now([comment_entry])

    expect { described_class.perform_now([comment_entry]) }.not_to change(CommentAutomation::MessageLog, :count)

    allow(CommentAutomation::PublicReplyJob).to receive(:perform_later)
    described_class.perform_now([comment_entry])
    expect(CommentAutomation::PublicReplyJob).not_to have_received(:perform_later)
  end
end
