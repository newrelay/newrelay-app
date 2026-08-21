# One LLM call over recent reviews → { sentiment: 0-100, insights: [{title, text}] }.
# ponytail: inherits BaseAiService (same as AiDraftService); caching lives in the controller.
class Reputation::AiInsightsService < Llm::BaseAiService
  MAX_REVIEWS = 50

  def initialize(account:)
    super()
    @account = account
  end

  def generate
    reviews = @account.reputation_reviews.order(reviewed_at: :desc).limit(MAX_REVIEWS).to_a
    return nil if reviews.empty?

    parsed = JSON.parse(sanitize_json_response(chat.ask(prompt(reviews)).content))
    {
      sentiment: parsed['sentiment'].to_i.clamp(0, 100),
      insights: Array(parsed['insights']).first(4).filter_map do |i|
        next unless i.is_a?(Hash)

        { title: i['title'].to_s, text: i['text'].to_s }
      end
    }
  rescue StandardError => e
    Rails.logger.error("Reputation AI insights failed for account #{@account.id}: #{e.message}")
    nil
  end

  private

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
