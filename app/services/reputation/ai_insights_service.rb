# One LLM call over recent reviews → { sentiment: 0-100, insights: [{title, text}] }.
# Falls back to stats from the same reviews when the LLM is missing or errors,
# so Overview is never stuck on the hardcoded Demo copy if reviews exist.
class Reputation::AiInsightsService < Llm::BaseAiService
  MAX_REVIEWS = 50

  def initialize(account:, listing_id: nil, listing_ids: nil)
    super()
    @account = account
    @listing_ids = Array(listing_ids.presence || listing_id)
  end

  def generate
    reviews = @account.reputation_reviews
                      .includes(:reputation_review_reply, :reputation_integration)
                      .order(reviewed_at: :desc)
                      .limit(MAX_REVIEWS)
    reviews = reviews.where(reputation_integration: { reputation_listing_id: @listing_ids }) if @listing_ids.present?
    reviews = reviews.to_a
    return nil if reviews.empty?

    from_llm(reviews) || from_reviews(reviews)
  end

  # Used by generate (LLM miss) and by specs. reviews: AR or duck-typed rows.
  # topics/keywords need real text analysis this fallback can't do without an
  # LLM, so they stay empty here rather than faking a topic model — the
  # frontend hides those sections when the arrays are empty.
  def from_reviews(reviews)
    total = reviews.size
    positive = reviews.count { |r| r.rating.to_i >= 4 }
    sentiment = ((positive * 100.0) / total).round
    unanswered = reviews.select { |r| unanswered_negative?(r) }
    pending = reviews.count { |r| pending_without_reply?(r) }

    insights = [
      { title: 'Review sentiment', text: "#{sentiment}% of your latest #{total} reviews are 4–5 stars." },
      reply_status_insight(unanswered, pending),
      top_platform_insight(reviews, total)
    ]

    { sentiment: sentiment, insights: insights, topics: [], keywords: [], suggestions: stats_suggestions(unanswered, pending) }
  end

  private

  def reply_status_insight(unanswered, pending)
    if unanswered.any?
      names = unanswered.map { |r| r.provider.to_s.humanize }.uniq
      { title: 'Action required',
        text: "#{unanswered.size} negative review#{'s' unless unanswered.one?} on #{names.join(', ')} have not been responded to." }
    elsif pending.positive?
      { title: 'Replies pending', text: "#{pending} review#{'s' unless pending == 1} still need a reply." }
    else
      { title: 'Replies up to date', text: 'All recent reviews have been handled.' }
    end
  end

  def top_platform_insight(reviews, total)
    top_name, top_count = reviews.group_by { |r| r.provider.to_s }.max_by { |_, rs| rs.size }
    { title: 'Top platform', text: "#{top_name.to_s.humanize} accounts for #{top_count.size} of #{total} recent reviews." }
  end

  def stats_suggestions(unanswered, pending)
    if unanswered.any?
      ["Reply to #{unanswered.size} negative review#{'s' unless unanswered.one?} that " \
       "#{unanswered.one? ? "hasn't" : "haven't"} been addressed yet."]
    elsif pending.positive?
      ["#{pending} review#{'s' unless pending == 1} still #{pending == 1 ? 'needs' : 'need'} a reply."]
    else
      []
    end
  end

  def from_llm(reviews)
    parsed = JSON.parse(sanitize_json_response(chat.ask(prompt(reviews)).content))
    insights = parse_insights(parsed)
    return nil if insights.blank?

    { sentiment: parsed['sentiment'].to_i.clamp(0, 100), insights: insights,
      topics: parse_topics(parsed), keywords: parse_keywords(parsed), suggestions: parse_suggestions(parsed) }
  rescue StandardError => e
    Rails.logger.error("Reputation AI insights failed for account #{@account.id}: #{e.message}")
    nil
  end

  def parse_insights(parsed)
    Array(parsed['insights']).first(4).filter_map do |i|
      next unless i.is_a?(Hash)

      { title: i['title'].to_s, text: i['text'].to_s }
    end
  end

  def parse_topics(parsed)
    Array(parsed['topics']).first(4).filter_map do |t|
      next unless t.is_a?(Hash) && t['name'].present?

      { name: t['name'].to_s, rating: t['rating'].to_f.clamp(1, 5).round(1) }
    end
  end

  def parse_keywords(parsed)
    Array(parsed['keywords']).first(8).filter_map { |k| k.to_s.presence }
  end

  def parse_suggestions(parsed)
    Array(parsed['suggestions']).first(3).filter_map { |s| s.to_s.presence }
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
       "insights": [{"title": "<3-5 word label>", "text": "<one actionable sentence>"}, ...3-4 items],
       "topics": [{"name": "<2-4 word recurring topic, e.g. 'Staff & Support'>", "rating": <1-5, avg sentiment customers express about this topic>}, ...up to 4 items, only real recurring topics],
       "keywords": ["<word or short phrase customers repeat>", ...up to 8 items],
       "suggestions": ["<one specific, actionable sentence for the business owner>", ...up to 3 items]}

      Only include topics/keywords that genuinely recur across multiple reviews below — omit the field (empty array) rather than inventing one from a single review.

      Reviews:
      #{lines}
    PROMPT
  end
end
