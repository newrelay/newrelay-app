require 'rails_helper'

RSpec.describe 'MCP auth', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before { account.enable_features!('mcp_integration') }

  it 'rejects a request with no Authorization header' do
    mcp_call('list_accounts', token: nil)

    expect(response).to have_http_status(:success) # JSON-RPC errors still return HTTP 200
    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/missing or invalid access token/i)
  end

  it 'rejects a request with an invalid token' do
    mcp_call('list_accounts', token: 'not-a-real-token')

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/missing or invalid access token/i)
  end

  it 'rejects an AgentBot-owned token' do
    agent_bot = create(:agent_bot, account: account)

    mcp_call('list_accounts', token: agent_bot.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/missing or invalid access token/i)
  end

  it 'accepts a valid User-owned token' do
    mcp_call('list_accounts', token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
  end
end
