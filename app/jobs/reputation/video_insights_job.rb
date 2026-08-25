# Runs transcription + AI analysis off the request cycle (transcription is slow),
# then persists the result to the testimonial's ai_insights column.
class Reputation::VideoInsightsJob < ApplicationJob
  queue_as :default

  def perform(testimonial)
    result = Reputation::VideoInsightsService.new(testimonial: testimonial).generate
    testimonial.update!(ai_insights: result)
  end
end
