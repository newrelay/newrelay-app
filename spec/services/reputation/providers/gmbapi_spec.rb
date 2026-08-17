require 'rails_helper'

RSpec.describe Reputation::Providers::Gmbapi do
  around do |example|
    with_modified_env(GMBAPI_BASE_URL: 'https://api.gmbapi.test/v1', GMBAPI_TOKEN: 'key') { example.run }
  end

  let(:integration) { instance_double(Reputation::Integration, location_id: 'loc-1') }

  describe '#list_reviews' do
    it 'normalizes both numeric and GBP-enum star ratings' do
      stub_request(:get, 'https://api.gmbapi.test/v1/locations/loc-1/reviews')
        .with(headers: { 'Authorization' => 'Bearer key' })
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: {
          reviews: [
            { reviewId: 'g1', starRating: 4, comment: 'nice', reviewer: { displayName: 'Ann' }, createTime: '2026-02-02T00:00:00Z' },
            { reviewId: 'g2', starRating: 'FIVE', comment: 'great', reviewer: { displayName: 'Bo' }, createTime: '2026-02-03T00:00:00Z' }
          ]
        }.to_json)

      result = described_class.new(integration).list_reviews
      expect(result.map { |r| r[:rating] }).to eq([4, 5])
      expect(result.first).to include(external_id: 'g1', body: 'nice', reviewer_name: 'Ann')
    end

    it 'raises on an unsuccessful response' do
      stub_request(:get, %r{api\.gmbapi\.test}).to_return(status: 401, body: 'bad token')
      expect { described_class.new(integration).list_reviews }.to raise_error(/GMBapi reviews fetch failed/)
    end
  end

  describe '#publish_reply' do
    it 'PUTs to the GMBapi reply endpoint with the bearer token' do
      review = instance_double(Reputation::Review, external_id: 'g1')
      stub = stub_request(:put, 'https://api.gmbapi.test/v1/locations/loc-1/reviews/g1/reply')
             .with(body: { comment: 'cheers' }.to_json, headers: { 'Authorization' => 'Bearer key' })
             .to_return(status: 200, body: '{}')

      described_class.new(integration).publish_reply(review, 'cheers')
      expect(stub).to have_been_requested
    end
  end
end
