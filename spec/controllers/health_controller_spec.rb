require 'rails_helper'

RSpec.describe 'Health Check', type: :request do
  describe 'GET /health' do
    it 'returns success status' do
      get '/health'
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['status']).to eq('woot')
    end
  end

  describe 'GET /ready' do
    it 'returns ready when database and redis respond' do
      get '/ready'
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['status']).to eq('ready')
      expect(response.parsed_body['checks']).to eq('database' => true, 'redis' => true)
    end

    it 'returns 503 when redis is down' do
      allow(Redis::Alfred).to receive(:with).and_raise(Redis::CannotConnectError)
      get '/ready'
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body['status']).to eq('degraded')
      expect(response.parsed_body['checks']['redis']).to be(false)
    end
  end
end
