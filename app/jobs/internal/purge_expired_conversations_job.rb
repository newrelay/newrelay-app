# purgable
# permanently deletes conversations/messages/attachments that have exceeded
# the account's plan data retention window (see PlanFeatureLimit#data_retention_months)

class Internal::PurgeExpiredConversationsJob < ApplicationJob
  queue_as :purgable

  def perform(account)
    Internal::PurgeExpiredConversationsService.new(account: account).perform
  end
end
