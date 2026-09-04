class Inboxes::SyncSocialAvatarJob < ApplicationJob
  queue_as :purgable

  def perform(inbox_id)
    inbox = Inbox.find_by(id: inbox_id)
    return if inbox.blank? || inbox.avatar.attached?

    Inboxes::SyncSocialAvatarService.new(inbox: inbox).perform
  end
end
