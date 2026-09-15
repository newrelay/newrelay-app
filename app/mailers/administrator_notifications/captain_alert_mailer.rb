class AdministratorNotifications::CaptainAlertMailer < AdministratorNotifications::BaseMailer
  def key_failure(action:, error_message:, account: nil)
    subject = 'Captain AI call failed — check your OpenAI/OpenRouter key'
    meta = {
      'action' => action,
      'error_message' => error_message,
      'account_id' => account&.id,
      'account_name' => account&.name
    }

    send_notification(subject, to: super_admin_emails, meta: meta)
  end

  private

  def super_admin_emails
    SuperAdmin.pluck(:email)
  end
end
