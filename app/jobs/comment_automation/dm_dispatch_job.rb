class CommentAutomation::DmDispatchJob < ApplicationJob
  queue_as :default

  NETWORK_ERRORS = [Net::ReadTimeout, Net::OpenTimeout, HTTParty::Error, SocketError].freeze

  def perform(message_log_id)
    log = CommentAutomation::MessageLog.find_by(id: message_log_id)
    return if log.blank? || !log.public_replied?

    rate_limiter = CommentAutomation::RateLimiter.new(inbox: log.inbox)
    unless rate_limiter.within_limit?
      self.class.set(wait: 1.second).perform_later(message_log_id)
      return
    end

    response = send_dm(log)
    rate_limiter.track_send

    if success_response?(response)
      mark_sent(log)
    else
      fail_log(log, response.parsed_response)
    end
  rescue *NETWORK_ERRORS => e
    fail_log(log, e.message)
  end

  private

  def success_response?(response)
    response.success? && response.parsed_response.is_a?(Hash) && response.parsed_response['error'].blank?
  end

  def mark_sent(log)
    log.update!(status: :dm_sent, sent_at: Time.current)
    Rails.logger.info(
      "[comment_automation] event=dm_sent campaign_id=#{log.trigger.campaign_id} " \
      "trigger_id=#{log.trigger_id} comment_id=#{log.comment_id}"
    )
  end

  def send_dm(log)
    channel = log.inbox.channel
    HTTParty.post(
      "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/#{channel.instagram_id}/messages",
      body: { recipient: { id: log.commenter_id }, message: { text: log.trigger.dm_text_body } },
      query: { access_token: channel.access_token }
    )
  end

  def fail_log(log, error)
    log.update!(status: :dm_failed)
    Rails.logger.error("[comment_automation] event=dm_failed comment_id=#{log.comment_id} error=#{error}")
  end
end
