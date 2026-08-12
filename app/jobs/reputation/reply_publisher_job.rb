# Posts a saved reply back to Google Business Profile or Facebook and marks it published.
class Reputation::ReplyPublisherJob < ApplicationJob
  queue_as :default

  def perform(reply_id)
    reply = Reputation::ReviewReply.find(reply_id)
    review = reply.reputation_review
    integration = review.reputation_integration

    integration.refresh_token! if integration.provider == 'google'

    publish(integration, review, reply)

    reply.update!(status: :published, published_at: Time.current)
    review.replied!
  end

  private

  def publish(integration, review, reply)
    case integration.provider
    when 'google'   then publish_google(integration, review, reply)
    when 'facebook' then publish_facebook(integration, review, reply)
    end
  end

  def publish_google(integration, review, reply)
    HTTParty.put(
      "https://mybusiness.googleapis.com/v4/#{review.external_id}/reply",
      headers: {
        'Authorization' => "Bearer #{integration.access_token}",
        'Content-Type' => 'application/json'
      },
      body: { comment: reply.body }.to_json
    ).tap { |r| raise "Google reply failed: #{r.body}" unless r.success? }
  end

  def publish_facebook(integration, review, reply)
    HTTParty.post(
      "https://graph.facebook.com/#{review.external_id}/comments",
      query: {
        access_token: integration.access_token,
        message: reply.body
      }
    ).tap { |r| raise "Facebook reply failed: #{r.body}" unless r.success? }
  end
end
