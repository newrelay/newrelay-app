require 'rails_helper'

RSpec.describe 'MCP get_conversation', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  it 'returns conversation detail by display_id' do
    mcp_call('get_conversation', arguments: { account_id: account.id, conversation_id: conversation.display_id },
                                 token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['id']).to eq(conversation.display_id)
  end

  it 'returns a tool error for an unknown conversation_id' do
    mcp_call('get_conversation', arguments: { account_id: account.id, conversation_id: 999_999 },
                                 token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/not found/i)
  end

  it 'returns the same not-found error for a real conversation the agent has no inbox/team access to' do
    other_inbox = create(:inbox, account: account)
    other_conversation = create(:conversation, account: account, inbox: other_inbox)

    mcp_call('get_conversation', arguments: { account_id: account.id, conversation_id: other_conversation.display_id },
                                 token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to eq("Conversation #{other_conversation.display_id} not found")
  end

  it 'allows an administrator to view any conversation in the account' do
    admin = create(:user, account: account, role: :administrator)
    other_inbox = create(:inbox, account: account)
    other_conversation = create(:conversation, account: account, inbox: other_inbox)

    mcp_call('get_conversation', arguments: { account_id: account.id, conversation_id: other_conversation.display_id },
                                 token: admin.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['id']).to eq(other_conversation.display_id)
  end
end
