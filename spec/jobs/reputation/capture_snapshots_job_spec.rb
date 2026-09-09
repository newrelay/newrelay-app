require 'rails_helper'

RSpec.describe Reputation::CaptureSnapshotsJob, type: :job do
  let(:account) { create(:account) }
  let(:integration) { create(:reputation_integration, account: account) }

  before { create(:reputation_review, account: account, reputation_integration: integration) }

  it 'backfills accounts that have reviews but no snapshot history yet' do
    recorder = instance_double(Reputation::SnapshotRecorder, backfill!: true)
    allow(Reputation::SnapshotRecorder).to receive(:new).with(account).and_return(recorder)

    described_class.perform_now

    expect(recorder).to have_received(:backfill!)
  end

  it 'captures a new snapshot for accounts that already have snapshot history' do
    account.reputation_snapshots.create!(provider: Reputation::Snapshot::ROLLUP_PROVIDER, captured_on: 1.day.ago.to_date)
    recorder = instance_double(Reputation::SnapshotRecorder, capture!: true)
    allow(Reputation::SnapshotRecorder).to receive(:new).with(account).and_return(recorder)

    described_class.perform_now

    expect(recorder).to have_received(:capture!)
  end

  it 'skips accounts that have no reviews at all' do
    reviewless_account = create(:account)

    described_class.perform_now

    expect(reviewless_account.reputation_snapshots.count).to eq(0)
  end
end
