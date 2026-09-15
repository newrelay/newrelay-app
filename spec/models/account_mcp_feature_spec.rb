require 'rails_helper'

RSpec.describe Account do
  describe 'mcp_integration feature flag' do
    let(:account) { create(:account) }

    it 'is disabled by default' do
      expect(account.feature_enabled?('mcp_integration')).to be false
    end

    it 'can be enabled' do
      account.enable_features!('mcp_integration')
      expect(account.feature_enabled?('mcp_integration')).to be true
    end
  end

  describe 'Featurable bit-position stability' do
    it 'keeps the original 63 bitfield features at their original positions' do
      expect(Featurable::DB_FEATURES.size).to eq(63)
      expect(Featurable::DB_FEATURES[1]).to eq(:feature_inbound_emails)
    end

    it 'treats mcp_integration as a virtual feature (stored in settings), not a bitfield column, since it is past the 63-feature bitfield cap' do
      expect(Featurable::VIRTUAL_FEATURES).to include('mcp_integration')
      expect(Featurable::DB_FEATURES.values).not_to include(:feature_mcp_integration)
    end
  end
end
