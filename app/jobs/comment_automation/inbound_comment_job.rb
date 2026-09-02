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

    campaign = CommentAutomation::Campaign.find_by(account_id: inbox.account_id, inbox_id: inbox.id,
                                                   post_id: comment.dig(:media, :id), is_active: true)
    return if campaign.blank?

    trigger = CommentAutomation::MatchEngine.new(campaign: campaign, comment: comment).match
    return if trigger.blank?

    log = create_log(trigger, inbox, comment)
    return if log.blank?

    Rails.logger.info("[comment_automation] event=matched campaign_id=#{campaign.id} trigger_id=#{trigger.id} comment_id=#{comment[:id]}")
    CommentAutomation::PublicReplyJob.perform_later(log.id)
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
