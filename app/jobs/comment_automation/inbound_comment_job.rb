class CommentAutomation::InboundCommentJob < ApplicationJob
  queue_as :default

  def perform(entries)
    Array(entries).each { |entry| process_entry(entry.with_indifferent_access) }
  end

  private

  def process_entry(entry)
    channel = Channel::Instagram.find_by(instagram_id: entry[:id])
    return if channel.blank? || channel.inbox.blank?

    Array(entry[:changes]).each do |change|
      next unless change[:field] == 'comments'

      process_comment(channel.inbox, change[:value].with_indifferent_access)
    end
  end

  def process_comment(inbox, comment)
    return if comment[:id].blank? || comment.dig(:from, :id).blank?

    campaigns = CommentAutomation::Campaign.active_for_post(inbox: inbox, post_id: comment.dig(:media, :id))

    campaigns.each do |campaign|
      trigger = CommentAutomation::MatchEngine.new(campaign: campaign, comment: comment).match
      next if trigger.blank?

      log = create_log(trigger, inbox, comment)
      next if log.blank?

      Rails.logger.info("[comment_automation] event=matched campaign_id=#{campaign.id} trigger_id=#{trigger.id} comment_id=#{comment[:id]}")
      enqueue_reply(log, inbox)
      return
    end
  end

  def enqueue_reply(log, inbox)
    if CommentAutomation.mock_channel?(inbox.channel)
      CommentAutomation::PublicReplyJob.perform_now(log.id)
    else
      CommentAutomation::PublicReplyJob.perform_later(log.id)
    end
  end

  def create_log(trigger, inbox, comment)
    CommentAutomation::MessageLog.create!(
      trigger: trigger, account: inbox.account, inbox: inbox,
      comment_id: comment[:id], commenter_id: comment.dig(:from, :id)
    )
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.info(
      "[comment_automation] event=duplicate_comment campaign_id=#{trigger.campaign_id} " \
      "trigger_id=#{trigger.id} comment_id=#{comment[:id]}"
    )
    nil
  end
end
