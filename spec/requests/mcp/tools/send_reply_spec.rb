require 'rails_helper'

RSpec.describe 'MCP send_reply', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  it 'sends a customer-visible reply' do
    mcp_call('send_reply', arguments: { account_id: account.id, conversation_id: conversation.display_id, content: 'hello there' },
                           token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    body = mcp_content_json
    expect(body['content']).to eq('hello there')
    expect(body['private']).to be false

    message = conversation.messages.find(body['id'])
    expect(message.private?).to be false
    expect(message.outgoing?).to be true
    expect(message.content_attributes['mcp']).to be true
  end

  it 'returns the same not-found error for a real conversation the agent has no inbox/team access to' do
    other_inbox = create(:inbox, account: account)
    other_conversation = create(:conversation, account: account, inbox: other_inbox)

    mcp_call('send_reply', arguments: { account_id: account.id, conversation_id: other_conversation.display_id, content: 'x' },
                           token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to eq("Conversation #{other_conversation.display_id} not found")
  end

  it 'returns a tool error for an unknown conversation_id' do
    mcp_call('send_reply', arguments: { account_id: account.id, conversation_id: 999_999, content: 'x' },
                           token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to eq('Conversation 999999 not found')
  end
end
