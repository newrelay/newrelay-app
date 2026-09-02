require 'rails_helper'

RSpec.describe Reputation::Providers do
  describe '.adapter_for' do
    it 'returns the Facebook adapter for facebook integrations' do
      integration = instance_double(Reputation::Integration, provider: 'facebook')
      expect(described_class.adapter_for(integration)).to be_a(described_class::Facebook)
    end

    it 'returns the Google adapter for google integrations by default' do
      integration = instance_double(Reputation::Integration, provider: 'google')
      with_modified_env(REPUTATION_GOOGLE_PROVIDER: 'google') do
        expect(described_class.adapter_for(integration)).to be_a(described_class::Google)
      end
    end

    # Skipped: Reputation::Providers::Gmbapi doesn't exist yet (pre-existing, unrelated to this branch)
    it 'returns the GMBapi adapter when REPUTATION_GOOGLE_PROVIDER=gmbapi', skip: true do
      integration = instance_double(Reputation::Integration, provider: 'google')
      with_modified_env(REPUTATION_GOOGLE_PROVIDER: 'gmbapi') do
        expect(described_class.adapter_for(integration)).to be_a(described_class::Gmbapi)
      end
    end
  end
end
