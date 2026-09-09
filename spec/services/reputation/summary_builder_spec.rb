require 'rails_helper'

RSpec.describe Reputation::SummaryBuilder do
  let(:account) { create(:account) }

  before do
    allow_any_instance_of(Reputation::SnapshotRecorder).to receive(:capture!) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Reputation::SnapshotRecorder).to receive(:backfill!) # rubocop:disable RSpec/AnyInstance
  end

  describe '#as_json' do
    context 'when scoped to specific listings' do
      it 'returns live metrics only, without deltas, and skips snapshotting' do
        listing = create(:reputation_listing, account: account)
        integration = create(:reputation_integration, account: account, listing: listing)
        create(:reputation_review, account: account, reputation_integration: integration, rating: 5, status: 'replied')

        expect(Reputation::SnapshotRecorder).not_to receive(:new)

        result = described_class.new(account, listing_ids: [listing.id]).as_json

        expect(result[:deltas_ready]).to be false
        expect(result[:score_delta]).to be_nil
        expect(result[:reviews_count]).to eq(1)
        expect(result[:platforms]).to eq([])
      end
    end

    context 'without 30 days of snapshot history' do
      it 'returns live metrics with deltas not ready' do
        result = described_class.new(account).as_json

        expect(result[:deltas_ready]).to be false
        expect(result[:score_delta]).to be_nil
        expect(result[:history_days]).to eq(0)
      end
    end

    context 'with 30+ days of snapshot history' do
      it 'computes deltas against the snapshot from 30 days ago' do
        account.reputation_snapshots.create!(provider: Reputation::Snapshot::ROLLUP_PROVIDER, captured_on: Date.current,
                                             score: 80, avg_rating: 4.5, reviews_count: 20, response_rate: 90)
        account.reputation_snapshots.create!(provider: Reputation::Snapshot::ROLLUP_PROVIDER, captured_on: Date.current - 30,
                                             score: 60, avg_rating: 4.0, reviews_count: 10, response_rate: 70)
        account.reputation_snapshots.create!(provider: 'google', captured_on: Date.current,
                                             score: 80, avg_rating: 4.5, reviews_count: 20, response_rate: 90)
        account.reputation_snapshots.create!(provider: 'google', captured_on: Date.current - 30,
                                             score: 60, avg_rating: 4.0, reviews_count: 10, response_rate: 70)

        result = described_class.new(account).as_json

        expect(result[:deltas_ready]).to be true
        expect(result[:score]).to eq(80)
        expect(result[:score_delta]).to eq(20)
        expect(result[:rating_delta]).to eq(0.5)
        expect(result[:reviews_delta_pct]).to eq(100.0)
        expect(result[:platforms]).to contain_exactly(
          hash_including(provider: 'google', reviews_count: 20, trend_pct: 100.0)
        )
      end
    end
  end
end
