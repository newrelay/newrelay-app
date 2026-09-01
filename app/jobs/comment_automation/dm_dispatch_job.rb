class CommentAutomation::DmDispatchJob < ApplicationJob
  queue_as :default

  def perform(message_log_id); end
end
