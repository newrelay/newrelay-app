require 'rails_helper'

RSpec.describe 'MCP set_priority', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent, priority: 'low') }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  it 'sets the conversation priority' do
    mcp_call('set_priority', arguments: { account_id: account.id, conversation_id: conversation.display_id, priority: 'urgent' },
                             token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['priority']).to eq('urgent')
    expect(conversation.reload.priority).to eq('urgent')
  end

  it 'clears the priority when given none' do
    mcp_call('set_priority', arguments: { account_id: account.id, conversation_id: conversation.display_id, priority: 'none' },
                             token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['priority']).to eq('none')
    expect(conversation.reload.priority).to be_nil
  end

  it 'rejects an invalid priority value' do
    mcp_call('set_priority', arguments: { account_id: account.id, conversation_id: conversation.display_id, priority: 'not-a-priority' },
                             token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/priority must be one of/i)
  end
end
