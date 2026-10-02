require 'rails_helper'

RSpec.describe Twilio::ElevenlabsKnowledgeService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_phone_number, account: account) }
  let(:hook) { create(:integrations_hook, app_id: 'elevenlabs', account: account, settings: { 'api_key' => 'account-key' }) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before do
    create(:captain_inbox, captain_assistant: assistant, inbox: channel.inbox)
    create(
      :captain_document,
      assistant: assistant,
      account: account,
      external_link: 'https://example.com/pricing',
      name: 'Pricing',
      status: :available
    )
  end

  it 'attaches the inbox website page to the phone agent' do
    expect(HTTParty).to receive(:post).with(
      described_class::ELEVENLABS_KNOWLEDGE_URL,
      hash_including(body: include('https://example.com/pricing'))
    ).and_return(instance_double(HTTParty::Response, success?: true, parsed_response: { 'id' => 'doc_1' }))
    expect(HTTParty).to receive(:patch).with(
      "#{Twilio::ConnectElevenlabsService::ELEVENLABS_AGENTS_URL}/agent_1",
      hash_including(body: include('doc_1').and(include('"enabled":true')))
    ).and_return(instance_double(HTTParty::Response, success?: true, parsed_response: {}))

    described_class.new(inbox: channel.inbox, hook: hook, agent_id: 'agent_1').perform
  end
end
