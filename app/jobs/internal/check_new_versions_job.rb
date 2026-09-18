class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless Rails.env.production?

    @instance_info = ChatwootHub.sync_with_hub
    update_version_info
  end

  private

  def update_version_info
    # NewRelay versions are independent of Chatwoot Hub releases.
    ::Redis::Alfred.delete(::Redis::Alfred::LATEST_CHATWOOT_VERSION)
  end
end

Internal::CheckNewVersionsJob.prepend_mod_with('Internal::CheckNewVersionsJob')
