# One LLM call over recent reviews → { sentiment: 0-100, insights: [{title, text}] }.
# Falls back to stats from the same reviews when the LLM is missing or errors,
# so Overview is never stuck on the hardcoded Demo copy if reviews exist.
class Reputation::AiInsightsService < Llm::BaseAiService
  MAX_REVIEWS = 50

  def initialize(account:)
    super()
    @account = account
  end

  def generate
    reviews = @account.reputation_reviews
                      .includes(:reputation_review_reply)
                      .order(reviewed_at: :desc)
                      .limit(MAX_REVIEWS)
                      .to_a
    return nil if reviews.empty?

    from_llm(reviews) || from_reviews(reviews)
  end

  # Used by generate (LLM miss) and by specs. reviews: AR or duck-typed rows.
  def from_reviews(reviews)
    total = reviews.size
    positive = reviews.count { |r| r.rating.to_i >= 4 }
    sentiment = ((positive * 100.0) / total).round
    unanswered = reviews.select { |r| unanswered_negative?(r) }
    pending = reviews.count { |r| pending_without_reply?(r) }
    top_name, top_count = reviews.group_by { |r| r.provider.to_s }.max_by { |_, rs| rs.size }

    insights = [{ title: 'Review sentiment',
                  text: "#{sentiment}% of your latest #{total} reviews are 4–5 stars." }]
    insights << if unanswered.any?
                  names = unanswered.map { |r| r.provider.to_s.humanize }.uniq
                  { title: 'Action required',
                    text: "#{unanswered.size} negative review#{'s' unless unanswered.one?} on #{names.join(', ')} have not been responded to." }
                elsif pending.positive?
                  { title: 'Replies pending',
                    text: "#{pending} review#{'s' unless pending == 1} still need a reply." }
                else
                  { title: 'Replies up to date', text: 'All recent reviews have been handled.' }
                end
    insights << { title: 'Top platform',
                  text: "#{top_name.to_s.humanize} accounts for #{top_count.size} of #{total} recent reviews." }

    { sentiment: sentiment, insights: insights }
  end

  private

  def from_llm(reviews)
    parsed = JSON.parse(sanitize_json_response(chat.ask(prompt(reviews)).content))
    insights = Array(parsed['insights']).first(4).filter_map do |i|
      next unless i.is_a?(Hash)

      { title: i['title'].to_s, text: i['text'].to_s }
    end
    return nil if insights.blank?

    { sentiment: parsed['sentiment'].to_i.clamp(0, 100), insights: insights }
  rescue StandardError => e
    Rails.logger.error("Reputation AI insights failed for account #{@account.id}: #{e.message}")
    nil
  end

  def unanswered_negative?(review)
    review.rating.to_i <= 3 && pending_without_reply?(review)
  end

  def pending_without_reply?(review)
    status = review.respond_to?(:status) ? review.status.to_s : ''
    reply = review.respond_to?(:reputation_review_reply) ? review.reputation_review_reply : nil
    status == 'pending' && reply.blank?
  end

  def prompt(reviews)
    lines = reviews.map { |r| "- [#{r.rating}/5] #{r.body.to_s.truncate(200)}" }.join("\n")
    <<~PROMPT
      You are a reputation analyst. Analyze these customer reviews and respond ONLY with JSON, no prose:
      {"sentiment": <integer 0-100, percent of reviews that are positive>,
       "insights": [{"title": "<3-5 word label>", "text": "<one actionable sentence>"}, ...3-4 items]}

      Reviews:
      #{lines}
    PROMPT
  end
end
