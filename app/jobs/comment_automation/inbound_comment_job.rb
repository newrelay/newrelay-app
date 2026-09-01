class CommentAutomation::InboundCommentJob < ApplicationJob
  queue_as :default

  def perform(entries); end
end
