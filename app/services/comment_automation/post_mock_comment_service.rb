class CommentAutomation::PostMockCommentService
  class Error < StandardError; end

  pattr_initialize [:account!, :text!, :name]

  def perform
    raise Error, I18n.t('comment_automation.mock.disabled') unless CommentAutomation.mock?
    raise Error, I18n.t('comment_automation.mock.comment_blank') if text.to_s.strip.blank?
    raise Error, I18n.t('comment_automation.mock.not_connected') if inbox.blank?
    raise Error, I18n.t('comment_automation.mock.no_campaign') if campaign.blank?

    CommentAutomation::InboundCommentJob.perform_now([payload])
    result_for(CommentAutomation::MessageLog.find_by(inbox: inbox, comment_id: comment_id))
  end

  private

  def inbox
    @inbox ||= Channel::Instagram.find_by(instagram_id: "mock-ig-#{account.id}")&.inbox
  end

  def campaign
    @campaign ||= account.comment_automation_campaigns.find_by(inbox: inbox, is_active: true)
  end

  def comment_id
    @comment_id ||= "mock-cmt-#{SecureRandom.hex(8)}"
  end

  def commenter_id
    @commenter_id ||= "mock-user-#{SecureRandom.hex(4)}"
  end

  def display_name
    name.to_s.strip.presence || 'You'
  end

  def payload
    {
      id: inbox.channel.instagram_id,
      changes: [{
        field: 'comments',
        value: {
          id: comment_id,
          text: text.to_s.strip,
          from: { id: commenter_id, username: display_name },
          media: { id: campaign.post_id }
        }
      }]
    }
  end

  def result_for(log)
    {
      matched: log.present?,
      comment: text.to_s.strip,
      name: display_name,
      public_reply: log && rotate_reply(log.trigger),
      dm: log&.trigger&.dm_text_body,
      status: log&.status
    }
  end

  def rotate_reply(trigger)
    replies = trigger.public_replies
    replies[(trigger.message_logs.count - 1) % replies.size]
  end
end
