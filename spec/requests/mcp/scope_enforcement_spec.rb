require 'rails_helper'

RSpec.describe 'MCP scope enforcement', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  context 'when the access token has an empty scopes array (the default)' do
    it 'allows a read tool call' do
      mcp_call('list_inboxes', arguments: { account_id: account.id }, token: agent.access_token.token)

      expect(mcp_result['isError']).to be false
    end

    it 'allows a write tool call' do
      mcp_call('add_private_note', arguments: { account_id: account.id, conversation_id: conversation.display_id, content: 'note' },
                                   token: agent.access_token.token)

      expect(mcp_result['isError']).to be false
    end
  end

  context 'when the access token is scoped to a specific set of tools' do
    before { agent.access_token.update!(scopes: ['list_inboxes']) }

    it 'allows a tool that is in scopes' do
      mcp_call('list_inboxes', arguments: { account_id: account.id }, token: agent.access_token.token)

      expect(mcp_result['isError']).to be false
    end

    it 'rejects a tool that is not in scopes' do
      mcp_call('add_private_note', arguments: { account_id: account.id, conversation_id: conversation.display_id, content: 'note' },
                                   token: agent.access_token.token)

      expect(mcp_result['isError']).to be true
      expect(mcp_result['content'].first['text']).to eq('This access token is not permitted to use add_private_note')
    end
  end
end
