require 'rails_helper'

RSpec.describe Reputation::ScoreCalculator do
  ScoreCalculatorReview = Struct.new(:rating, :status, :reviewed_at, keyword_init: true)

  it 'scores a perfect recent inbox at 100' do
    reviews = Array.new(10) do
      ScoreCalculatorReview.new(rating: 5, status: 'replied', reviewed_at: Time.current)
    end
    expect(described_class.new(reviews).metrics[:score]).to eq(100)
  end

  it 'returns zeros for an empty inbox' do
    expect(described_class.new([]).metrics).to include(
      score: 0,
      reviews_count: 0,
      avg_rating: 0.0,
      response_rate: 0.0
    )
  end

  it 'weights rating, response rate, and velocity' do
    reviews = [
      ScoreCalculatorReview.new(rating: 5, status: 'replied', reviewed_at: Time.current),
      ScoreCalculatorReview.new(rating: 5, status: 'pending', reviewed_at: Time.current)
    ]
    metrics = described_class.new(reviews).metrics
    # rating 50 + response 15 + velocity (2/10)*20 = 4 → 69
    expect(metrics[:score]).to eq(69)
    expect(metrics[:response_rate]).to eq(50.0)
  end
end
