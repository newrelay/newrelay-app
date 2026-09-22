require 'rails_helper'

RSpec.describe 'MCP set_status', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent, status: 'open') }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  it 'changes the conversation status' do
    mcp_call('set_status', arguments: { account_id: account.id, conversation_id: conversation.display_id, status: 'resolved' },
                           token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['status']).to eq('resolved')
    expect(conversation.reload.status).to eq('resolved')
  end

  it 'snoozes with a snoozed_until timestamp' do
    mcp_call('set_status', arguments: { account_id: account.id, conversation_id: conversation.display_id, status: 'snoozed',
                                        snoozed_until: '2026-09-25T09:00:00Z' },
                           token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['status']).to eq('snoozed')
    conversation.reload
    expect(conversation.status).to eq('snoozed')
    expect(conversation.snoozed_until).to eq(Time.zone.parse('2026-09-25T09:00:00Z'))
  end

  it 'rejects an invalid status value' do
    mcp_call('set_status', arguments: { account_id: account.id, conversation_id: conversation.display_id, status: 'deleted' },
                           token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/status must be one of/i)
    expect(conversation.reload.status).to eq('open')
  end
end
