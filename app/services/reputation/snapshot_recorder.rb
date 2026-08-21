# Writes daily cumulative snapshots used for month-over-month deltas.
# Backfill reconstructs history from review.reviewed_at so accounts with
# older reviews can get honest deltas without waiting 30 calendar days.
class Reputation::SnapshotRecorder
  LOOKBACK_DAYS = 90

  def initialize(account)
    @account = account
  end

  def capture!(on: Date.current)
    write_for(on, @account.reputation_reviews.to_a)
  end

  def backfill!(days: LOOKBACK_DAYS)
    reviews = @account.reputation_reviews.to_a
    return capture!(on: Date.current) if reviews.empty?

    dated = reviews.map { |review| review.reviewed_at&.to_date }.compact
    start_on = dated.min || Date.current
    floor = Date.current - days
    start_on = floor if start_on < floor

    (start_on..Date.current).each { |on| write_for(on, reviews) }
  end

  private

  def write_for(on, reviews)
    eligible = reviews.select { |review| include_review?(review, on) }
    upsert(on, Reputation::Snapshot::ROLLUP_PROVIDER, eligible)

    eligible.group_by { |review| review.provider }.each do |provider, group|
      upsert(on, provider, group)
    end
  end

  def include_review?(review, on)
    return on == Date.current if review.reviewed_at.blank?

    review.reviewed_at.to_date <= on
  end

  def upsert(on, provider, reviews)
    metrics = Reputation::ScoreCalculator.new(reviews, as_of: on).metrics
    snapshot = Reputation::Snapshot.find_or_initialize_by(
      account: @account,
      provider: provider,
      captured_on: on
    )
    snapshot.update!(metrics)
  end
end
