module Llm::ExceptionTrackable
  NOTIFICATION_THROTTLE = 15.minutes

  private

  def capture_llm_exception(error, credential:)
    log_captain_activity_failure(error)

    if credential && credential[:source] == :system
      ChatwootExceptionTracker.new(error, account: exception_tracking_account).capture_exception
    else
      Rails.logger.error("[LLM] account=#{exception_tracking_account&.id} #{error.class}: #{error.message}")
    end
  end

  def log_captain_activity_failure(error)
    log = CaptainActivityLog.create!(
      account: exception_tracking_account,
      action: event_name,
      status: 'failed',
      error_class: error.class.name,
      message: error.message.to_s.truncate(2000)
    )
    notify_super_admins_of_captain_failure(error, log)
  rescue StandardError => e
    Rails.logger.error("[CaptainActivityLog] failed to record failure: #{e.class}: #{e.message}")
  end

  # DB-backed throttle (not Rails.cache — some environments run a null cache
  # store, which would silently defeat an in-memory throttle) so a provider
  # outage sends one email, not one per failed call.
  def notify_super_admins_of_captain_failure(error, log)
    return if CaptainActivityLog.where.not(notified_at: nil).where(notified_at: NOTIFICATION_THROTTLE.ago..).exists?

    log.update!(notified_at: Time.current)
    AdministratorNotifications::CaptainAlertMailer.key_failure(
      action: event_name,
      error_message: error.message.to_s.truncate(500),
      account: exception_tracking_account
    ).deliver_later
  rescue StandardError => e
    Rails.logger.error("[CaptainAlertMailer] failed to queue notification: #{e.class}: #{e.message}")
  end
end
