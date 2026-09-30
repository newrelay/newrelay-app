require 'rails_helper'

RSpec.describe NumberProvisioning::VoiceAgentAttachService do
  subject(:attach) { described_class.new(order: order).perform }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:order) do
    account.number_provisioning_orders.create!(
      country_code: 'US',
      phone_number: '+14155550134',
      provider_type: 'telnyx',
      status: 'active',
      inbox: inbox
    )
  end

  before do
    assistant = Captain::Assistant.create!(account: account, name: 'Relay', description: 'Answers calls')
    CaptainInbox.create!(inbox: inbox, captain_assistant: assistant)
    create(
      :integrations_hook,
      app_id: 'elevenlabs',
      account: account,
      settings: { 'api_key' => 'account-key', 'voice_id' => '21m00Tcm4TlvDq8ikWAM' }
    )
  end

  it 'saves the row from the account ElevenLabs hook and does not store the key' do
    expect(HTTParty).not_to receive(:post)
    expect(HTTParty).not_to receive(:get)

    row = attach
    again = described_class.new(order: order.reload).perform

    expect(row.id).to eq(again.id)
    expect(row.status).to eq('saved')
    expect(row.previous_sip_target).to be_nil
    expect(row.public_id).to be_present
    expect(row.attributes.to_json).not_to include('account-key')
  end

  it 'refuses an order that is not active' do
    order.update!(status: 'order_placed')

    expect { attach }.to raise_error(described_class::Error, 'voice_agent_not_active')
    expect(order.reload.voice_agent).to be_nil
  end

  it 'records a missing ElevenLabs Voice AI integration' do
    Integrations::Hook.where(account_id: account.id, app_id: 'elevenlabs').delete_all

    expect { attach }.to raise_error(described_class::Error, 'voice_agent_credentials_missing')
    expect(order.reload.voice_agent.failure_code).to eq('voice_agent_credentials_missing')
  end

  it 'records a missing Relay AI brain' do
    CaptainInbox.where(inbox_id: inbox.id).delete_all

    expect { attach }.to raise_error(described_class::Error, 'voice_agent_brain_missing')
    expect(order.reload.voice_agent.failure_code).to eq('voice_agent_brain_missing')
  end

  it 'saves an India number without changing the call route' do
    order.update!(country_code: 'IN', phone_number: '+918045678901', provider_type: 'exotel')
    expect(HTTParty).not_to receive(:post)

    row = attach

    expect(row.status).to eq('saved')
    expect(row.previous_sip_target).to be_nil
  end

  it 'imports a matching Twilio number into ElevenLabs without storing the token' do
    channel = create(
      :channel_twilio_sms, :with_phone_number,
      account: account,
      phone_number: order.phone_number,
      account_sid: 'AC123',
      auth_token: 'twilio-secret'
    )
    response = instance_double(HTTParty::Response, success?: true, parsed_response: { 'phone_number_id' => 'ph_1' })
    expect(HTTParty).to receive(:post).with(
      described_class::ELEVENLABS_PHONE_NUMBERS_URL,
      hash_including(body: include('AC123').and(include(order.phone_number)))
    ).and_return(response)

    row = attach

    expect(row.elevenlabs_phone_number_id).to eq('ph_1')
    expect(row.attributes.to_json).not_to include(channel.auth_token)
  end

  it 'records a rejected Twilio import' do
    create(:channel_twilio_sms, :with_phone_number, account: account, phone_number: order.phone_number)
    response = instance_double(HTTParty::Response, success?: false, code: 422, parsed_response: {})
    allow(HTTParty).to receive(:post).and_return(response)

    expect { attach }.to raise_error(described_class::Error, 'voice_agent_twilio_rejected')
    expect(order.reload.voice_agent.failure_code).to eq('voice_agent_twilio_rejected')
    expect(order.voice_agent.elevenlabs_phone_number_id).to be_nil
  end

  it 'retries a failed row into a saved row' do
    Integrations::Hook.where(account_id: account.id, app_id: 'elevenlabs').delete_all
    expect { attach }.to raise_error(described_class::Error)

    create(
      :integrations_hook,
      app_id: 'elevenlabs',
      account: account,
      settings: { 'api_key' => 'account-key', 'voice_id' => '21m00Tcm4TlvDq8ikWAM' }
    )
    row = described_class.new(order: order.reload).perform

    expect(row.status).to eq('saved')
    expect(row.failure_code).to be_nil
    expect(NumberProvisioning::VoiceAgent.where(order_id: order.id).count).to eq(1)
  end
end
