# Weighted 0–100 score from a set of reviews as of a given date.
#   50 pts — average rating / 5
#   30 pts — reply rate (replied / total)
#   20 pts — velocity (reviews in the last 30 days, capped at 10)
class Reputation::ScoreCalculator
  RATING_WEIGHT = 50.0
  RESPONSE_WEIGHT = 30.0
  VELOCITY_WEIGHT = 20.0
  VELOCITY_TARGET = 10

  def initialize(reviews, as_of: Time.current)
    @reviews = Array(reviews)
    @as_of = as_of
  end

  def metrics
    count = @reviews.size
    avg = count.zero? ? 0.0 : (@reviews.sum { |review| review.rating.to_f } / count)
    replied = @reviews.count { |review| review.status.to_s == 'replied' }
    rate = count.zero? ? 0.0 : (replied.to_f / count) * 100

    {
      reviews_count: count,
      avg_rating: avg.round(2),
      response_rate: rate.round(2),
      score: compute_score(avg, rate, velocity_count)
    }
  end

  private

  def velocity_count
    from = @as_of.to_date - 29.days
    to = @as_of.to_date
    @reviews.count do |review|
      next false if review.reviewed_at.blank?

      day = review.reviewed_at.to_date
      day >= from && day <= to
    end
  end

  def compute_score(avg, rate, velocity)
    rating_part = (avg / 5.0) * RATING_WEIGHT
    response_part = (rate / 100.0) * RESPONSE_WEIGHT
    velocity_part = [[velocity.to_f / VELOCITY_TARGET, 1.0].min, 0.0].max * VELOCITY_WEIGHT
    (rating_part + response_part + velocity_part).round.clamp(0, 100)
  end
end
