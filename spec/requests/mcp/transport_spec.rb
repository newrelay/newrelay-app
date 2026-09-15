require 'rails_helper'

RSpec.describe 'MCP transport', type: :request do
  describe 'GET /mcp/sse' do
    it 'does not open an SSE stream (no unauthenticated broadcast target can ever exist)' do
      get '/mcp/sse'

      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to match(%r{application/json})
      expect(response.parsed_body['error']['message']).to eq('Endpoint not found')
    end
  end
end
