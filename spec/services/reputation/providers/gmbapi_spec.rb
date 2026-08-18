require 'rails_helper'

RSpec.describe Reputation::Providers::Gmbapi do
  around do |example|
    with_modified_env(GMBAPI_BASE_URL: 'https://api.gmbapi.test/external-api/gmb', GMBAPI_TOKEN: 'key') { example.run }
  end

  let(:integration) { instance_double(Reputation::Integration, location_id: 'loc-1') }

  describe '#list_reviews' do
    it 'POSTs to /review/location and normalizes the review objects' do
      stub_request(:post, 'https://api.gmbapi.test/external-api/gmb/review/location')
        .with(headers: { 'Authorization' => 'Bearer key' })
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: {
          data: [
            { review_name: 'accounts/1/locations/9/reviews/r1', rating: 5, comment_native: 'super',
              comment_en: 'great', reviewerName: 'Ann', created_date: 1_700_000_000_000_000 }
          ]
        }.to_json)

      result = described_class.new(integration).list_reviews
      expect(result.first).to include(
        external_id: 'accounts/1/locations/9/reviews/r1', rating: 5, body: 'super', reviewer_name: 'Ann'
      )
      expect(result.first[:reviewed_at]).to eq(Time.zone.at(1_700_000_000))
    end

    it 'raises on an unsuccessful response' do
      stub_request(:post, %r{api\.gmbapi\.test}).to_return(status: 500, body: 'boom')
      expect { described_class.new(integration).list_reviews }.to raise_error(/GMBapi reviews fetch failed/)
    end
  end

  describe '#publish_reply' do
    it 'POSTs the reply to /review/answer with review_name and comment' do
      review = instance_double(Reputation::Review, external_id: 'accounts/1/locations/9/reviews/r1')
      stub = stub_request(:post, 'https://api.gmbapi.test/external-api/gmb/review/answer')
             .with(
               body: { location_id: 'loc-1', review_name: 'accounts/1/locations/9/reviews/r1', comment: 'cheers' }.to_json,
               headers: { 'Authorization' => 'Bearer key' }
             )
             .to_return(status: 200, body: '{}')

      described_class.new(integration).publish_reply(review, 'cheers')
      expect(stub).to have_been_requested
    end
  end
end
