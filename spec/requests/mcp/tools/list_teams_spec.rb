require 'rails_helper'

RSpec.describe 'MCP list_teams', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:team) { create(:team, account: account, name: 'Support Team') }

  before { account.enable_features!('mcp_integration') }

  it 'lists teams in the account' do
    mcp_call('list_teams', arguments: { account_id: account.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    teams = mcp_content_json
    expect(teams.map { |t| t['id'] }).to eq([team.id])
    expect(teams.first['name']).to eq('support team')
  end
end
