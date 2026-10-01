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
      settings: { 'api_key' => 'account-key' }
    )
  end

  it 'sends the account auth token when the channel uses a Twilio API key' do
    channel.update!(api_key_sid: 'SK123', api_key_secret: 'key-secret', auth_token: 'account-auth')
    response = instance_double(HTTParty::Response, success?: true, parsed_response: { 'phone_number_id' => 'phn_key' })
    expect(HTTParty).to receive(:post).with(
      described_class::ELEVENLABS_PHONE_NUMBERS_URL,
      hash_including(body: include('SK123').and(include('account_auth_token')).and(include('"enable_sms":false')))
    ).and_return(response)

    expect(connect.elevenlabs_phone_number_id).to eq('phn_key')
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