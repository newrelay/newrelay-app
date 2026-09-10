require 'rails_helper'

RSpec.describe Reputation::AiInsightsService do
  AiInsightsReview = Struct.new(:rating, :provider, :status, :reputation_review_reply, :body, keyword_init: true)

  it 'builds insights from review stats when the LLM is unavailable' do
    reviews = [
      AiInsightsReview.new(rating: 5, provider: 'google', status: 'replied', reputation_review_reply: Object.new),
      AiInsightsReview.new(rating: 5, provider: 'google', status: 'pending', reputation_review_reply: nil),
      AiInsightsReview.new(rating: 2, provider: 'google', status: 'pending', reputation_review_reply: nil)
    ]
    result = described_class.allocate.from_reviews(reviews)

    expect(result[:sentiment]).to eq(67)
    expect(result[:insights].map { |i| i[:title] }).to include('Action required', 'Top platform')
    expect(result[:insights][1][:text]).to include('1 negative review on Google')
  end
end
