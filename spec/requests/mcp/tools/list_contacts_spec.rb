require 'rails_helper'

RSpec.describe 'MCP list_contacts', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:matching_contact) { create(:contact, account: account, name: 'Ada Lovelace', email: 'ada@example.com') }
  let!(:other_contact) { create(:contact, account: account, name: 'Bob Smith', email: 'bob@example.com') }

  before { account.enable_features!('mcp_integration') }

  it 'searches contacts by name' do
    mcp_call('list_contacts', arguments: { account_id: account.id, search: 'Ada' }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    contacts = mcp_content_json
    expect(contacts.map { |c| c['id'] }).to eq([matching_contact.id])
  end

  it 'returns contacts without a search term' do
    mcp_call('list_contacts', arguments: { account_id: account.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json.map { |c| c['id'] }).to include(matching_contact.id, other_contact.id)
  end
end
