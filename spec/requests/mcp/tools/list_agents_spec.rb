require 'rails_helper'

RSpec.describe 'MCP list_agents', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent, name: 'Ada Lovelace') }

  before { account.enable_features!('mcp_integration') }

  it 'lists agents in the account with their role' do
    mcp_call('list_agents', arguments: { account_id: account.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    agents = mcp_content_json
    expect(agents.find { |a| a['id'] == agent.id }).to include('name' => 'Ada Lovelace', 'role' => 'agent')
  end
end
