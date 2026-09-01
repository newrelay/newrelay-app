# Runs transcription + AI analysis off the request cycle (transcription is slow),
# then persists the result to the testimonial's ai_insights column.
class Reputation::VideoInsightsJob < ApplicationJob
  queue_as :default

  def perform(testimonial)
    result = Reputation::VideoInsightsService.new(testimonial: testimonial).generate
    testimonial.update!(ai_insights: result)
  rescue StandardError => e
    # Client init (missing CAPTAIN_OPEN_AI_API_KEY) raises before #generate's rescue.
    Rails.logger.error("Video insights job failed for testimonial #{testimonial.id}: #{e.message}")
    testimonial.update!(ai_insights: { 'error' => e.message })
  end
end
