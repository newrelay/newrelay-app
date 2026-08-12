class AdministratorNotifications::EnterpriseInquiryMailer < AdministratorNotifications::BaseMailer
  def submitted(account:, user:, inquiry:)
    return if instance_admin_email.blank?

    subject = "Enterprise plan inquiry from #{account.name} (##{account.id})"
    meta = build_meta(account, user, inquiry)

    send_notification(subject, to: instance_admin_email, meta: meta)
  end

  private

  def build_meta(account, user, inquiry)
    {
      'account_id' => account.id,
      'account_name' => account.name,
      'requested_by_name' => user.name,
      'requested_by_email' => user.email,
      'company_size' => inquiry['company_size'].presence || 'Not specified',
      'team_size' => inquiry['team_size'].presence || 'Not specified',
      'desired_features' => Array(inquiry['desired_features']),
      'message' => inquiry['message'].presence || 'None'
    }
  end

  def instance_admin_email
    GlobalConfig.get('CHATWOOT_INSTANCE_ADMIN_EMAIL')['CHATWOOT_INSTANCE_ADMIN_EMAIL']
  end
end
