require 'rails_helper'

RSpec.describe Reputation::Providers::Google do
  let(:integration) do
    instance_double(Reputation::Integration, access_token: 'gtoken', location_id: 'accounts/1/locations/9')
  end

  describe '#list_reviews' do
    it 'normalizes GBP enum star ratings to integers' do
      stub_request(:get, 'https://mybusiness.googleapis.com/v4/accounts/1/locations/9/reviews')
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: {
          reviews: [
            { name: 'accounts/1/locations/9/reviews/r1', starRating: 'THREE', comment: 'ok',
              reviewer: { displayName: 'Sam' }, createTime: '2026-01-01T00:00:00Z' }
          ]
        }.to_json)

      expect(described_class.new(integration).list_reviews).to eq(
        [{ external_id: 'accounts/1/locations/9/reviews/r1', rating: 3, body: 'ok',
           reviewer_name: 'Sam', reviewed_at: '2026-01-01T00:00:00Z' }]
      )
    end

    it 'returns [] when the access token is blank' do
      allow(integration).to receive(:access_token).and_return(nil)
      expect(described_class.new(integration).list_reviews).to eq([])
    end

    it 'raises on an unsuccessful response' do
      stub_request(:get, %r{mybusiness\.googleapis\.com}).to_return(status: 403, body: 'denied')
      expect { described_class.new(integration).list_reviews }.to raise_error(/Google reviews fetch failed/)
    end
  end

  describe '#publish_reply' do
    it 'PUTs the reply to the review reply endpoint' do
      review = instance_double(Reputation::Review, external_id: 'accounts/1/locations/9/reviews/r1')
      stub = stub_request(:put, 'https://mybusiness.googleapis.com/v4/accounts/1/locations/9/reviews/r1/reply')
             .with(body: { comment: 'thanks' }.to_json)
             .to_return(status: 200, body: '{}')

      described_class.new(integration).publish_reply(review, 'thanks')
      expect(stub).to have_been_requested
    end
  end
end
