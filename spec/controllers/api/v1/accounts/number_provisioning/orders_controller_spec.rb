require 'rails_helper'

RSpec.describe 'Number provisioning orders API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token.merge('Idempotency-Key' => 'key-1') }
  let(:redis) { {} }

  before do
    allow(Redis::Alfred).to receive(:set) do |key, value, **opts|
      if opts[:nx] && redis.key?(key)
        false
      else
        redis[key] = value
        true
      end
    end
    allow(Redis::Alfred).to receive(:get) { |key| redis[key] }
    allow(Redis::Alfred).to receive(:setex) { |key, value, _ttl| redis[key] = value }
    allow(Redis::Alfred).to receive(:delete) { |key| redis.delete(key) }
  end

  def order_url
    "/api/v1/accounts/#{account.id}/number_provisioning/orders"
  end

  describe 'POST /orders' do
    let(:provider) { instance_double(NumberProvisioning::TelnyxProvider) }

    before do
      allow(provider).to receive(:class).and_return(NumberProvisioning::TelnyxProvider)
      allow(provider).to receive(:order).and_return({ 'id' => 'ord_1' })
      allow(NumberProvisioning).to receive(:for).and_return(provider)
      redis['number_provisioning:quote:v2:US:+12025550100'] = { monthly_price_cents: 150, currency: 'USD' }.to_json
    end

    it 'rejects a country other than US or IN without calling the provider' do
      allow(NumberProvisioning).to receive(:for).and_call_original
      expect(HTTParty).not_to receive(:get)
      expect(HTTParty).not_to receive(:post)

      post order_url,
           params: { order: { country_code: 'GB', phone_number: '+442075551000' } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(provider).not_to have_received(:order)
    end

    it 'does not call the provider when the search cache has no price' do
      redis.delete('number_provisioning:quote:v2:US:+12025550100')

      post order_url,
           params: { order: { country_code: 'US', phone_number: '+12025550100' } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to include('price')
      expect(provider).not_to have_received(:order)
    end

    it 'refuses a second live order for the same number' do
      NumberProvisioning::Order.create!(
        account: account, provider_type: 'telnyx', country_code: 'US', phone_number: '+12025550100',
        status: 'active', provider_cost_cents: 150, currency: 'USD'
      )

      post order_url,
           params: { order: { country_code: 'US', phone_number: '+12025550100' } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(provider).not_to have_received(:order)
    end

    it 'marks the order failed when the provider times out before an id exists' do
      allow(provider).to receive(:order).and_raise(Net::ReadTimeout)

      expect do
        post order_url,
             params: { order: { country_code: 'US', phone_number: '+12025550100' } },
             headers: headers,
             as: :json
      end.not_to have_enqueued_job(NumberProvisioning::PollOrderStatusJob)

      order = NumberProvisioning::Order.last
      expect(order.status).to eq('failed')
      expect(order.failure_code).to eq('timeout')
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'enqueues the poll when a timeout happens after the provider order id was saved' do
      allow(provider).to receive(:order) do
        NumberProvisioning::Order.last.update!(provider_order_id: 'ord_saved')
        raise Net::ReadTimeout
      end

      expect do
        post order_url,
             params: { order: { country_code: 'US', phone_number: '+12025550100' } },
             headers: headers,
             as: :json
      end.to have_enqueued_job(NumberProvisioning::PollOrderStatusJob)

      expect(NumberProvisioning::Order.last.provider_order_id).to eq('ord_saved')
    end
  end

  describe 'GET /orders' do
    it 'returns the plain-language sentence and not the vendor body' do
      NumberProvisioning::Order.create!(
        account: account, provider_type: 'exotel', country_code: 'IN', phone_number: '+919148175645',
        status: 'failed', failure_code: 'insufficient_balance', provisioning_error: 'VENDOR_BODY_34005'
      )

      get order_url, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      body = response.parsed_body.first
      expect(body['failure_message']).to include('enough balance')
      expect(response.body).not_to include('VENDOR_BODY_34005')
      expect(body['unfinished']).to be(false)
    end
  end
end
