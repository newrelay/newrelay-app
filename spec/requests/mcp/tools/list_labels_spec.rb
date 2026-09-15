require 'rails_helper'

RSpec.describe 'MCP list_labels', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:label) { create(:label, account: account, title: 'billing', color: '#1f93ff') }

  before { account.enable_features!('mcp_integration') }

  it 'lists labels in the account' do
    mcp_call('list_labels', arguments: { account_id: account.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    labels = mcp_content_json
    expect(labels).to eq([{ 'id' => label.id, 'title' => 'billing', 'color' => '#1f93ff', 'description' => label.description }])
  end
end
