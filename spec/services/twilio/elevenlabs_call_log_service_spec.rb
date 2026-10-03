require 'rails_helper'

RSpec.describe Twilio::ElevenlabsCallLogService do
  let(:account) { create(:account) }
  let!(:channel) { create(:channel_twilio_sms, :with_phone_number, account: account, elevenlabs_agent_id: 'agent_1') }
  let(:payload) do
    {
      'type' => 'post_call_transcription',
      'data' => {
        'agent_id' => 'agent_1',
        'conversation_id' => 'conv_1',
        'transcript' => [
          { 'role' => 'agent', 'message' => 'Hello, how can I help you?' },
          { 'role' => 'user', 'message' => 'I need a callback.' }
        ],
        'conversation_initiation_client_data' => {
          'dynamic_variables' => { 'system__caller_id' => '+14155552671' }
        }
      }
    }
  end

  it 'saves the call transcript on the Twilio inbox' do
    described_class.new(account: account, payload: payload).perform

    conversation = channel.inbox.conversations.last
    expect(conversation.contact.phone_number).to eq('+14155552671')
    agent = conversation.messages.find_by!(content: 'Hello, how can I help you?')
    caller = conversation.messages.find_by!(content: 'I need a callback.')
    expect(agent).to be_outgoing
    expect(agent.private).to be(false)
    expect(caller).to be_incoming
    expect(caller.private).to be(false)
    expect(caller.sender).to eq(conversation.contact)
  end

  it 'does not save the same call twice' do
    described_class.new(account: account, payload: payload).perform
    described_class.new(account: account, payload: payload).perform

    expect(channel.inbox.messages.where(source_id: 'elevenlabs:conv_1:0').count).to eq(1)
  end
end