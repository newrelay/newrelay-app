# spec/jobs/comment_automation/dm_dispatch_job_spec.rb
require 'rails_helper'

RSpec.describe CommentAutomation::DmDispatchJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account, instagram_id: 'ig-account-1') }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }
  let(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account, dm_text_body: 'Here is the link!') }
  let(:log) do
    create(:comment_automation_message_log, trigger: trigger, account: account, inbox: inbox,
                                             comment_id: 'comment-1', commenter_id: 'commenter-1', status: :public_replied)
  end

  # The job appends the channel's access_token as a query param (matching the rest of the
  # codebase's graph.instagram.com calls), so stubs match on a regex rather than the bare
  # path, which WebMock would otherwise treat as requiring an empty query string.
  let(:messages_url) { %r{\Ahttps://graph\.instagram\.com/v22\.0/ig-account-1/messages} }

  it 'sends a DM and marks the log dm_sent' do
    stub_request(:post, messages_url).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    described_class.perform_now(log.id)

    expect(log.reload.status).to eq 'dm_sent'
    expect(log.sent_at).to be_present
  end

  it 'sends the recipient id and message text from the trigger' do
    stub = stub_request(:post, messages_url)
           .with(body: { recipient: { id: 'commenter-1' }, message: { text: 'Here is the link!' } })
           .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    described_class.perform_now(log.id)

    expect(stub).to have_been_requested
  end

  it 'marks the log dm_failed when the API returns an error' do
    stub_request(:post, messages_url).to_return(status: 200, body: '{"error":{"message":"bad token"}}', headers: { 'Content-Type' => 'application/json' })

    described_class.perform_now(log.id)

    expect(log.reload.status).to eq 'dm_failed'
  end

  it 'marks the log dm_failed when the network call itself raises a timeout' do
    stub_request(:post, messages_url).to_timeout

    described_class.perform_now(log.id)

    expect(log.reload.status).to eq 'dm_failed'
  end

  it 'requeues instead of sending when the inbox is over the rate limit' do
    allow_any_instance_of(CommentAutomation::RateLimiter).to receive(:within_limit?).and_return(false)

    expect { described_class.perform_now(log.id) }.to have_enqueued_job(described_class).with(log.id)
  end

  it 'does nothing if the log is not public_replied' do
    log.update!(status: :pending)

    expect(HTTParty).not_to receive(:post)
    described_class.perform_now(log.id)
  end
end
