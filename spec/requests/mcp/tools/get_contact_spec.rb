require 'rails_helper'

RSpec.describe 'MCP get_contact', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:contact) { create(:contact, account: account, name: 'Ada Lovelace') }

  before { account.enable_features!('mcp_integration') }

  it 'returns contact detail by id' do
    mcp_call('get_contact', arguments: { account_id: account.id, contact_id: contact.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be false
    expect(mcp_content_json['id']).to eq(contact.id)
    expect(mcp_content_json['name']).to eq('Ada Lovelace')
  end

  it 'returns a tool error for an unknown contact_id' do
    mcp_call('get_contact', arguments: { account_id: account.id, contact_id: 999_999 }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    expect(mcp_result['content'].first['text']).to match(/not found/i)
  end
end
