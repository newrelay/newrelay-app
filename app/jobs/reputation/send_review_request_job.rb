# Delivers a single review request (email/SMS) off the request thread.
# Used for immediate sends and by the cron when a scheduled request comes due.
class Reputation::SendReviewRequestJob < ApplicationJob
  queue_as :default

  def perform(request_id)
    request = Reputation::ReviewRequest.find_by(id: request_id)
    return if request.nil?

    Reputation::ReviewRequestSendService.new(
      account: request.account,
      template_id: request.reputation_template_id,
      contact_id: request.contact_id
    ).deliver!(request)
  end
end
