require 'rails_helper'

RSpec.describe 'MCP BaseTool error handling', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before { account.enable_features!('mcp_integration') }

  it 'returns a generic error instead of a backtrace when a tool raises an unexpected error' do
    # FastMcp instantiates the tool internally per-request, so there's no other seam to stub.
    allow_any_instance_of(Mcp::ListInboxesTool).to receive(:perform).and_raise(StandardError, 'boom') # rubocop:disable RSpec/AnyInstance

    mcp_call('list_inboxes', arguments: { account_id: account.id }, token: agent.access_token.token)

    expect(mcp_result['isError']).to be true
    text = mcp_result['content'].first['text']
    expect(text).to eq('Something went wrong')
    expect(text).not_to match(/boom/)
    expect(text).not_to match(%r{/app/tools|\.rb:\d+})
  end
end
