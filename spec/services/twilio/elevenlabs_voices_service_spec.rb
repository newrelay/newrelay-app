require 'rails_helper'

RSpec.describe Twilio::ElevenlabsVoicesService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:hook) do
    create(:integrations_hook, app_id: 'elevenlabs', account: account, settings: { 'api_key' => 'account-key' })
  end

  def voice_row(name: 'Mine')
    account.elevenlabs_voices.create!(
      name: name,
      status: :pending,
      consent_statement: ElevenlabsVoice::CONSENT_SENTENCE,
      consent_accepted_at: Time.current
    )
  end

  before { hook }

  it 'shows a clone that is still missing from the live list' do
    voice_row
    allow(HTTParty).to receive(:get).and_return(
      instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'voices' => [{ 'voice_id' => 'v1', 'name' => 'Rachel' }], 'has_more' => false }
      )
    )

    names = service.list[:voices].map { |voice| voice[:name] }

    expect(names).to eq(['Mine', 'Rachel'])
    expect(service.list[:voices].first[:selectable]).to be(false)
  end

  it 'keeps tone and persona on the voice' do
    voice = voice_row
    voice.update!(tone: 'warm', persona: 'front desk')
    allow(HTTParty).to receive(:get).and_return(
      instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: {
          'voices' => [
            {
              'voice_id' => 'v1',
              'name' => 'Rachel',
              'description' => 'narrator',
              'labels' => { 'description' => 'calm', 'accent' => 'american' }
            }
          ],
          'has_more' => false
        }
      )
    )

    rows = service.list[:voices]
    mine = rows.find { |item| item[:name] == 'Mine' }
    rachel = rows.find { |item| item[:name] == 'Rachel' }

    expect(mine[:tone]).to eq('warm')
    expect(mine[:persona]).to eq('front desk')
    expect(rachel[:tone]).to eq('calm')
    expect(rachel[:persona]).to eq('narrator')
    expect(rachel[:traits]).to eq('american')
  end

  it 'refuses a clip that is too large' do
    clip = instance_double(
      ActionDispatch::Http::UploadedFile,
      blank?: false,
      size: 11.megabytes,
      content_type: 'audio/mpeg',
      original_filename: 'clip.mp3'
    )

    expect do
      service.enqueue(name: 'A', clip: clip, consent: true)
    end.to raise_error(Twilio::ConnectElevenlabsService::Error, 'voice_clip_invalid')
  end

  it 'marks the clone failed when ElevenLabs rejects the upload' do
    voice = voice_row
    voice.clip.attach(io: StringIO.new('audio'), filename: 'clip.mp3', content_type: 'audio/mpeg')
    allow(HTTParty).to receive(:post).and_return(
      instance_double(HTTParty::Response, success?: false, code: 422, parsed_response: {})
    )

    service.create_remote(voice)

    expect(voice.reload).to be_failed
    expect(voice.error_message).to eq('ElevenLabs: 422')
  end

  it 'stores the voice id when the clone is created' do
    voice = voice_row
    voice.clip.attach(io: StringIO.new('audio'), filename: 'clip.mp3', content_type: 'audio/mpeg')
    allow(HTTParty).to receive(:post).and_return(
      instance_double(HTTParty::Response, success?: true, parsed_response: { 'voice_id' => 'clone_1' })
    )
    allow(HTTParty).to receive(:get).and_return(
      instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'preview_url' => 'https://example.com/preview.mp3', 'requires_verification' => false }
      )
    )

    service.create_remote(voice)

    expect(voice.reload).to be_ready
    expect(voice.voice_id).to eq('clone_1')
    expect(voice.preview_url).to eq('https://example.com/preview.mp3')
  end

  it 'puts the website pages back when changing the speaking voice removes them' do
    before = { 'knowledge_base' => [{ 'id' => 'doc' }], 'rag' => { 'enabled' => true } }
    allow(HTTParty).to receive(:get).and_return(
      instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'conversation_config' => { 'agent' => { 'prompt' => before } } }
      ),
      instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'conversation_config' => { 'agent' => { 'prompt' => {} } } }
      )
    )
    bodies = []
    allow(HTTParty).to receive(:patch) do |_url, options|
      bodies << options[:body]
      instance_double(HTTParty::Response, success?: true, parsed_response: {})
    end

    service.apply_voice(hook, 'agent_1', 'voice_1')

    expect(bodies.length).to eq(2)
    expect(bodies.last).to include('knowledge_base')
  end
end

RSpec.describe Twilio::AssignElevenlabsVoiceService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_phone_number, account: account) }

  before do
    create(:integrations_hook, app_id: 'elevenlabs', account: account, settings: { 'api_key' => 'account-key' })
    allow(HTTParty).to receive(:get).and_return(
      instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'voices' => [{ 'voice_id' => 'v1', 'name' => 'Rachel' }], 'has_more' => false }
      )
    )
  end

  it 'saves the voice before an agent exists' do
    described_class.new(inbox: channel.inbox, voice_id: 'v1').perform

    expect(channel.reload.elevenlabs_voice_id).to eq('v1')
  end

  it 'keeps the previous voice when ElevenLabs rejects the change' do
    channel.update!(elevenlabs_agent_id: 'agent_1', elevenlabs_voice_id: 'old')
    allow(HTTParty).to receive(:get).and_return(
      instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'voices' => [{ 'voice_id' => 'v1', 'name' => 'Rachel' }], 'has_more' => false }
      ),
      instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'conversation_config' => { 'agent' => { 'prompt' => {} } } }
      )
    )
    allow(HTTParty).to receive(:patch).and_return(
      instance_double(HTTParty::Response, success?: false, code: 400, parsed_response: {})
    )

    expect do
      described_class.new(inbox: channel.inbox, voice_id: 'v1').perform
    end.to raise_error(Twilio::ConnectElevenlabsService::Error, 'ElevenLabs: 400')
    expect(channel.reload.elevenlabs_voice_id).to eq('old')
  end
end
