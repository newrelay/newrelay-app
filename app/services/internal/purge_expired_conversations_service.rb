# Permanently deletes conversations (and their messages/attachments, via the
# existing Conversation destroy cascade) once they exceed the account's plan
# data retention window (account.limits['data_retention_months']).
#
# A blank/nil retention limit means unlimited retention (e.g. Enterprise) -
# such accounts are never purged.
class Internal::PurgeExpiredConversationsService
  # Cap per run so one large account can't monopolize the purgable queue;
  # the next scheduled run picks up any remainder.
  BATCH_LIMIT = 5000

  def initialize(account:)
    @account = account
  end

  def perform
    return 0 if retention_months.blank?

    total_deleted = 0

    expired_conversations.find_in_batches(batch_size: 1000) do |batch|
      conversation_ids = batch.map(&:id)
      Conversation.where(id: conversation_ids).destroy_all
      total_deleted += batch.size
      break if total_deleted >= BATCH_LIMIT
    end

    Rails.logger.info(
      "[PurgeExpiredConversationsService] Account #{@account.id}: deleted #{total_deleted} conversations " \
      "older than #{retention_months} month(s)"
    )
    total_deleted
  end

  private

  def retention_months
    @retention_months ||= @account.limits['data_retention_months']
  end

  def expired_conversations
    @account.conversations.where('last_activity_at < ?', retention_months.to_i.months.ago)
  end
end
