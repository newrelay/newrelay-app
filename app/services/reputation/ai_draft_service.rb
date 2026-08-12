# Generates an AI reply draft for a review using the existing Llm::BaseAiService.
# ponytail: inherits BaseAiService — no new LLM client, no config
class Reputation::AiDraftService < Llm::BaseAiService
  def initialize(review:)
    super()
    @review = review
  end

  def generate
    response = chat.ask(prompt)
    response.content.strip
  end

  private

  def prompt
    <<~PROMPT
      You are a professional customer service manager. Write a brief, friendly, and professional reply
      to the following customer review. Keep it under 100 words. Do not include a subject line or greeting header.

      Platform: #{@review.provider}
      Rating: #{@review.rating}/5
      Review: #{@review.body.presence || '(No text provided)'}
    PROMPT
  end
end
