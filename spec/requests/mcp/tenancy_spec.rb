require 'rails_helper'

RSpec.describe 'MCP tenancy', type: :request do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    account.enable_features!('mcp_integration')
    other_account.enable_features!('mcp_integration')
  end

  it 'rejects a call for an account the token owner does not belong to' do
    mcp_call('list_conversations', arguments: { account_id: other_account.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/account not found or not accessible/i)
  end
end
