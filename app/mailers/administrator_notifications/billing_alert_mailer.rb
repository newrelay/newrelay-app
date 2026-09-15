class AdministratorNotifications::BillingAlertMailer < AdministratorNotifications::BaseMailer
  def payment_failure(action:, message:, account: nil, payment_provider: nil)
    subject = 'Payment failure on your newrelay instance'
    meta = {
      'action' => action,
      'message' => message,
      'payment_provider' => payment_provider,
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
