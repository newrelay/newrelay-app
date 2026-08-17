# Posts a saved reply back to the review's provider (Google/GMBapi/Facebook) and
# marks it published. Provider HTTP lives in Reputation::Providers::*.
class Reputation::ReplyPublisherJob < ApplicationJob
  queue_as :default

  def perform(reply_id)
    reply = Reputation::ReviewReply.find(reply_id)
    review = reply.reputation_review
    integration = review.reputation_integration

    integration.refresh_token! if integration.provider == 'google'

    Reputation::Providers.adapter_for(integration).publish_reply(review, reply.body)

    reply.update!(status: :published, published_at: Time.current)
    review.replied!
  end
end
