require 'rails_helper'

RSpec.describe 'MCP remove_label', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent, label_list: %w[billing urgent keep]) }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  it 'removes labels from a conversation, keeping the rest' do
    mcp_call('remove_label', arguments: { account_id: account.id, conversation_id: conversation.display_id, labels: %w[billing urgent] },
                             token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['labels']).to eq(['keep'])
  end
end
