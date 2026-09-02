require 'rails_helper'

RSpec.describe CommentAutomation::RateLimiter do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:rate_limiter) { described_class.new(inbox: inbox) }

  it 'is within limit with no recent sends' do
    expect(rate_limiter.within_limit?).to be true
  end

  it 'is over limit after tracking 10 sends in the same window' do
    10.times { rate_limiter.track_send }

    expect(rate_limiter.within_limit?).to be false
  end

  it 'fails closed when Redis raises an error' do
    allow(Redis::Alfred).to receive(:keys_count).and_raise(Redis::BaseError, 'connection lost')

    expect(rate_limiter.within_limit?).to be false
  end
end
