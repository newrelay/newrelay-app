class CommentAutomation::PublicReplyJob < ApplicationJob
  queue_as :default

  NETWORK_ERRORS = [Net::ReadTimeout, Net::OpenTimeout, HTTParty::Error, SocketError,
                    Errno::ECONNREFUSED, OpenSSL::SSL::SSLError, Timeout::Error].freeze

  def perform(message_log_id)
    log = CommentAutomation::MessageLog.find_by(id: message_log_id)
    return if log.blank? || !log.pending?

    response = post_reply(log, rotate_reply(log.trigger))

    if success_response?(response)
      mark_replied(log)
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

  def mark_replied(log)
    log.update!(status: :public_replied)
    Rails.logger.info(
      "[comment_automation] event=public_replied campaign_id=#{log.trigger.campaign_id} " \
      "trigger_id=#{log.trigger_id} comment_id=#{log.comment_id}"
    )
    CommentAutomation::DmDispatchJob.set(wait: rand(3..12).seconds).perform_later(log.id)
  end

  def rotate_reply(trigger)
    replies = trigger.public_replies
    index = trigger.message_logs.count % replies.size
    replies[index]
  end

  def post_reply(log, text)
    HTTParty.post(
      "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/#{CGI.escape(log.comment_id)}/replies",
      body: { message: text },
      query: { access_token: log.inbox.channel.access_token }
    )
  end

  def fail_log(log, error)
    log.update!(status: :dm_failed)
    Rails.logger.error(
      "[comment_automation] event=public_reply_failed campaign_id=#{log.trigger.campaign_id} " \
      "trigger_id=#{log.trigger_id} comment_id=#{log.comment_id} error=#{error}"
    )
  end
end
