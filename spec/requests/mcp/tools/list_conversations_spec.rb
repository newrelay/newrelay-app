require 'rails_helper'

RSpec.describe 'MCP list_conversations', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  it 'returns the account\'s open conversations by default' do
    mcp_call('list_conversations', arguments: { account_id: account.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    conversations = mcp_content_json
    expect(conversations.map { |c| c['id'] }).to include(conversation.display_id)
  end
end
