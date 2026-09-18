require 'rails_helper'

RSpec.describe Internal::CheckNewVersionsJob do
  subject(:job) { described_class.perform_now }

  it 'does not treat Chatwoot Hub versions as NewRelay product updates' do
    data = { 'version' => '1.2.3' }
    allow(Rails.env).to receive(:production?).and_return(true)
    allow(ChatwootHub).to receive(:sync_with_hub).and_return(data)
    Redis::Alfred.set(Redis::Alfred::LATEST_CHATWOOT_VERSION, '4.14.1')
    job
    expect(ChatwootHub).to have_received(:sync_with_hub)
    expect(Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION)).to be_nil
  end
end
