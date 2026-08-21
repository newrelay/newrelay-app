# Overview payload: live score + honest month-over-month deltas.
# Deltas stay nil until a snapshot at least 30 days old exists.
class Reputation::SummaryBuilder
  HISTORY_DAYS = 30

  def initialize(account)
    @account = account
  end

  def as_json
    ensure_today_snapshot
    current = snapshot_on(Date.current, Reputation::Snapshot::ROLLUP_PROVIDER)
    prior = snapshot_on(Date.current - HISTORY_DAYS, Reputation::Snapshot::ROLLUP_PROVIDER)
    live = live_metrics
    ready = deltas_ready?(current, prior)

    {
      score: current&.score || live[:score],
      score_delta: ready ? current.score - prior.score : nil,
      avg_rating: (current&.avg_rating || live[:avg_rating]).to_f,
      rating_delta: ready ? (current.avg_rating.to_f - prior.avg_rating.to_f).round(1) : nil,
      reviews_count: current&.reviews_count || live[:reviews_count],
      reviews_delta_pct: reviews_delta_pct(current, prior, ready),
      response_rate: (current&.response_rate || live[:response_rate]).to_f,
      history_days: history_days,
      deltas_ready: ready,
      platforms: platform_rows(ready)
    }
  end

  private

  def ensure_today_snapshot
    recorder = Reputation::SnapshotRecorder.new(@account)
    if @account.reputation_snapshots.exists?
      recorder.capture!
    else
      recorder.backfill!
    end
  rescue StandardError => e
    Rails.logger.error("Reputation summary snapshot capture failed for account #{@account.id}: #{e.message}")
  end

  def live_metrics
    Reputation::ScoreCalculator.new(@account.reputation_reviews.to_a).metrics
  end

  def snapshot_on(on, provider)
    @account.reputation_snapshots.find_by(provider: provider, captured_on: on)
  end

  def oldest_rollup_on
    @account.reputation_snapshots.where(provider: Reputation::Snapshot::ROLLUP_PROVIDER).minimum(:captured_on)
  end

  def history_days
    oldest = oldest_rollup_on
    return 0 unless oldest

    (Date.current - oldest).to_i
  end

  def deltas_ready?(current, prior)
    current.present? && prior.present? && history_days >= HISTORY_DAYS
  end

  def reviews_delta_pct(current, prior, ready)
    return nil unless ready && prior.reviews_count.positive?

    (((current.reviews_count - prior.reviews_count).to_f / prior.reviews_count) * 100).round(1)
  end

  def platform_rows(ready)
    today = Date.current
    providers = @account.reputation_snapshots
                        .where(captured_on: today)
                        .where.not(provider: Reputation::Snapshot::ROLLUP_PROVIDER)
                        .order(:provider)

    providers.map do |row|
      prior = snapshot_on(today - HISTORY_DAYS, row.provider)
      trend = if ready && prior&.reviews_count.to_i.positive?
                (((row.reviews_count - prior.reviews_count).to_f / prior.reviews_count) * 100).round(1)
              end
      {
        provider: row.provider,
        avg_rating: row.avg_rating.to_f,
        reviews_count: row.reviews_count,
        trend_pct: trend
      }
    end
  end
end
