require 'rails_helper'

RSpec.describe Reputation::SnapshotRecorder do
  let(:account) { create(:account) }
  let(:google_integration) { create(:reputation_integration, account: account, provider: 'google') }
  let(:facebook_integration) { create(:reputation_integration, account: account, provider: 'facebook') }

  describe '#capture!' do
    it 'writes a rollup snapshot and a per-provider snapshot for today' do
      create(:reputation_review, account: account, reputation_integration: google_integration, rating: 5,
                                 status: 'replied', reviewed_at: Time.current)
      create(:reputation_review, account: account, reputation_integration: facebook_integration, provider: 'facebook',
                                 rating: 3, status: 'pending', reviewed_at: Time.current)

      described_class.new(account).capture!

      rollup = account.reputation_snapshots.find_by(provider: Reputation::Snapshot::ROLLUP_PROVIDER, captured_on: Date.current)
      google_snapshot = account.reputation_snapshots.find_by(provider: 'google', captured_on: Date.current)

      expect(rollup.reviews_count).to eq(2)
      expect(google_snapshot.reviews_count).to eq(1)
    end

    it 'updates the existing snapshot for the day instead of duplicating it' do
      create(:reputation_review, account: account, reputation_integration: google_integration, rating: 5,
                                 status: 'replied', reviewed_at: Time.current)
      recorder = described_class.new(account)

      expect { recorder.capture! }.to change { account.reputation_snapshots.count }.by(2)
      expect { recorder.capture! }.not_to(change { account.reputation_snapshots.count })
    end
  end

  describe '#backfill!' do
    it 'writes only a current-day snapshot when there are no reviews' do
      described_class.new(account).backfill!

      expect(account.reputation_snapshots.pluck(:captured_on)).to eq([Date.current])
    end

    it 'reconstructs history from the oldest review date' do
      travel_to Date.new(2026, 1, 10) do
        create(:reputation_review, account: account, reputation_integration: google_integration, rating: 4,
                                   status: 'replied', reviewed_at: 2.days.ago)

        described_class.new(account).backfill!

        rollup_days = account.reputation_snapshots.where(provider: Reputation::Snapshot::ROLLUP_PROVIDER).pluck(:captured_on)
        expect(rollup_days).to contain_exactly(Date.new(2026, 1, 8), Date.new(2026, 1, 9), Date.new(2026, 1, 10))
      end
    end
  end
end
