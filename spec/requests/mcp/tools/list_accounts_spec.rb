require 'rails_helper'

RSpec.describe 'MCP list_accounts', type: :request do
  let(:enabled_account) { create(:account, name: 'Enabled Co') }
  let(:disabled_account) { create(:account, name: 'Disabled Co') }
  let(:agent) { create(:user) }

  before do
    enabled_account.enable_features!('mcp_integration')
    create(:account_user, account: enabled_account, user: agent)
    create(:account_user, account: disabled_account, user: agent)
  end

  it 'returns only accounts with mcp_integration enabled' do
    mcp_call('list_accounts', token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    accounts = mcp_content_json
    expect(accounts).to eq([{ 'id' => enabled_account.id, 'name' => 'Enabled Co' }])
  end
end
