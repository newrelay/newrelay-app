require 'rails_helper'

RSpec.describe 'MCP add_label', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent, label_list: ['existing']) }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  it 'adds labels to a conversation, keeping existing ones' do
    create(:label, account: account, title: 'billing')
    create(:label, account: account, title: 'urgent')

    mcp_call('add_label', arguments: { account_id: account.id, conversation_id: conversation.display_id, labels: %w[billing urgent] },
                          token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['labels']).to match_array(%w[existing billing urgent])
  end

  it 'rejects a label that does not exist as a real account label' do
    mcp_call('add_label', arguments: { account_id: account.id, conversation_id: conversation.display_id, labels: ['not-a-real-label'] },
                          token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/unknown labels/i)
    expect(conversation.reload.label_list).not_to include('not-a-real-label')
  end

  it 'normalizes a case-variant of a real label before attaching it' do
    create(:label, account: account, title: 'billing')

    mcp_call('add_label', arguments: { account_id: account.id, conversation_id: conversation.display_id, labels: ['BILLING'] },
                          token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['labels']).to include('billing')
    expect(conversation.reload.label_list).not_to include('BILLING')
  end
end
