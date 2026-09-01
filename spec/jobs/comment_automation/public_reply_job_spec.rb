require 'rails_helper'

RSpec.describe CommentAutomation::PublicReplyJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account) }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }
  let(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account, public_replies: ['Thanks!', 'Check your DMs!']) }
  let(:log) { create(:comment_automation_message_log, trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1') }

  # The job appends the channel's access_token as a query param (matching the rest of the
  # codebase's graph.instagram.com calls), so stubs match on a regex rather than the bare
  # path, which WebMock would otherwise treat as requiring an empty query string.
  let(:reply_url) { %r{\Ahttps://graph\.instagram\.com/v22\.0/comment-1/replies} }

  it 'posts a reply to the Instagram comment and marks the log public_replied' do
    stub_request(:post, reply_url).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    described_class.perform_now(log.id)

    expect(log.reload.status).to eq 'public_replied'
  end

  it 'enqueues CommentAutomation::DmDispatchJob after a successful reply' do
    stub_request(:post, reply_url).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    expect { described_class.perform_now(log.id) }.to have_enqueued_job(CommentAutomation::DmDispatchJob).with(log.id)
  end

  it 'marks the log dm_failed and does not enqueue a DM when the reply call fails' do
    stub_request(:post, reply_url).to_return(status: 400, body: '{"error":"bad request"}')

    expect { described_class.perform_now(log.id) }.not_to have_enqueued_job(CommentAutomation::DmDispatchJob)
    expect(log.reload.status).to eq 'dm_failed'
  end

  it 'marks the log dm_failed when the network call itself raises a timeout' do
    stub_request(:post, reply_url).to_timeout

    expect { described_class.perform_now(log.id) }.not_to have_enqueued_job(CommentAutomation::DmDispatchJob)
    expect(log.reload.status).to eq 'dm_failed'
  end

  it 'marks the log dm_failed when the connection is refused' do
    stub_request(:post, reply_url).to_raise(Errno::ECONNREFUSED)

    expect { described_class.perform_now(log.id) }.not_to have_enqueued_job(CommentAutomation::DmDispatchJob)
    expect(log.reload.status).to eq 'dm_failed'
  end

  it 'does nothing if the log is not pending' do
    log.update!(status: :engaged)

    expect { described_class.perform_now(log.id) }.not_to have_enqueued_job(CommentAutomation::DmDispatchJob)
  end
end
