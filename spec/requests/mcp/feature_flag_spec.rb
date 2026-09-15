require 'rails_helper'

RSpec.describe 'MCP feature flag gating', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  it 'fails every account-scoped tool call when mcp_integration is disabled' do
    mcp_call('list_conversations', arguments: { account_id: account.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/mcp access is not enabled/i)
  end
end
