require 'rails_helper'

RSpec.describe 'MCP assign_conversation', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
    create(:inbox_member, inbox: inbox, user: other_agent)
  end

  it 'assigns the conversation to an agent' do
    mcp_call('assign_conversation', arguments: { account_id: account.id, conversation_id: conversation.display_id, agent_id: other_agent.id },
                                    token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['assignee']).to eq(other_agent.name)
    expect(conversation.reload.assignee).to eq(other_agent)
  end

  it 'assigns the conversation to a team' do
    # Team#name is normalized to lowercase by a before_validation callback (see app/models/team.rb),
    # so the persisted/returned name is 'support', not the 'Support' passed to the factory.
    team = create(:team, account: account, name: 'Support')

    mcp_call('assign_conversation', arguments: { account_id: account.id, conversation_id: conversation.display_id, team_id: team.id },
                                    token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['team']).to eq(team.name)
    expect(conversation.reload.team).to eq(team)
  end

  it 'rejects a call that provides neither agent_id nor team_id' do
    mcp_call('assign_conversation', arguments: { account_id: account.id, conversation_id: conversation.display_id },
                                    token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/exactly one of agent_id or team_id/i)
  end

  it 'rejects a call that provides both agent_id and team_id' do
    team = create(:team, account: account, name: 'Support')

    mcp_call('assign_conversation',
             arguments: { account_id: account.id, conversation_id: conversation.display_id, agent_id: other_agent.id, team_id: team.id },
             token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/exactly one of agent_id or team_id/i)
  end

  it 'rejects a nonexistent agent_id without touching the existing assignment' do
    mcp_call('assign_conversation', arguments: { account_id: account.id, conversation_id: conversation.display_id, agent_id: 999_999 },
                                    token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to eq('Agent 999999 not found')
    expect(conversation.reload.assignee).to eq(agent)
  end
end
