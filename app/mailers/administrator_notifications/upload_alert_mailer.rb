class AdministratorNotifications::UploadAlertMailer < AdministratorNotifications::BaseMailer
  def attachment_failure(action:, message:, account: nil)
    subject = 'File upload failure on your newrelay instance'
    meta = {
      'action' => action,
      'message' => message,
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
