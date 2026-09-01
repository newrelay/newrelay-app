class CommentAutomation::PublicReplyJob < ApplicationJob
  queue_as :default

  def perform(message_log_id); end
end
