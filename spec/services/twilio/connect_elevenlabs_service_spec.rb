require 'rails_helper'

RSpec.describe Twilio::ConnectElevenlabsService do
  subject(:connect) { described_class.new(inbox: channel.inbox).perform }

  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_phone_number, account: account) }

  before do
    create(
      :integrations_hook,
      app_id: 'elevenlabs',
      account: account,
      settings: { 'api_key' => 'account-key', 'voice_id' => 'voice-1' }
    )
    allow(HTTParty).to receive(:post).and_return(
      instance_double(HTTParty::Response, success?: true, code: 200, parsed_response: { 'agent_id' => 'agent_1' })
    )
    allow(HTTParty).to receive(:patch).and_return(
      instance_double(HTTParty::Response, success?: true, parsed_response: {})
    )
  end

  it 'sends the Twilio account auth token when the inbox also has an API key' do
    channel.update!(account_sid: 'AC123', api_key_sid: 'SK123', api_key_secret: 'key-secret', auth_token: 'account-auth')
    response = instance_double(HTTParty::Response, success?: true, parsed_response: { 'phone_number_id' => 'phn_key' })
    expect(HTTParty).to receive(:post).with(
      described_class::ELEVENLABS_PHONE_NUMBERS_URL,
      hash_including(body: include('AC123').and(include('account-auth')).and(include('"enable_sms":false')).and(include('agent_1')))
    ).and_return(response)

    expect(connect.elevenlabs_phone_number_id).to eq('phn_key')
  end

  it 'keeps a number ElevenLabs already has and assigns the agent' do
    failed = instance_double(
      HTTParty::Response,
      success?: false,
      code: 422,
      parsed_response: { 'detail' => [{ 'msg' => 'Phone number already exists' }] }
    )
    expect(HTTParty).to receive(:post).with(described_class::ELEVENLABS_PHONE_NUMBERS_URL, anything).and_return(failed)
    allow(HTTParty).to receive(:get).and_return(
      instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: [{ 'phone_number' => channel.phone_number, 'phone_number_id' => 'phn_existing' }]
      )
    )

    connect

    expect(channel.reload.elevenlabs_phone_number_id).to eq('phn_existing')
  end

  it 'imports the Twilio number and does not require a purchased phone number' do
    response = instance_double(HTTParty::Response, success?: true, parsed_response: { 'phone_number_id' => 'phn_1' })
    expect(HTTParty).to receive(:post).with(
      described_class::ELEVENLABS_PHONE_NUMBERS_URL,
      hash_including(headers: hash_including('xi-api-key' => 'account-key'))
    ).and_return(response)

    connect

    expect(channel.reload.elevenlabs_phone_number_id).to eq('phn_1')
    expect(HTTParty).not_to receive(:post)
    expect(described_class.new(inbox: channel.inbox).perform).to eq(channel)
  end

  it 'raises when ElevenLabs is not connected' do
    Integrations::Hook.where(account: account, app_id: 'elevenlabs').delete_all

    expect { connect }.to raise_error(Twilio::ConnectElevenlabsService::Error, 'voice_agent_credentials_missing')
    expect(channel.reload.elevenlabs_phone_number_id).to be_nil
  end
end