require 'rails_helper'

RSpec.describe 'MCP list_inboxes', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:inbox) { create(:inbox, account: account, name: 'Support') }
  let!(:other_inbox) { create(:inbox, account: account, name: 'Sales') }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  it 'lists only the inboxes the agent is assigned to' do
    mcp_call('list_inboxes', arguments: { account_id: account.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json).to eq([{ 'id' => inbox.id, 'name' => 'Support', 'channel_type' => inbox.channel_type }])
  end

  it 'lists every inbox in the account for an administrator' do
    admin = create(:user, account: account, role: :administrator)

    mcp_call('list_inboxes', arguments: { account_id: account.id }, token: admin.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json.map { |i| i['id'] }).to contain_exactly(inbox.id, other_inbox.id)
  end
end
