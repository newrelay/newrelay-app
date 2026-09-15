module Enterprise::BillingActivityLogging
  extend ActiveSupport::Concern

  BILLING_NOTIFICATION_THROTTLE = 15.minutes

  private

  def log_billing_activity(action:, message:, status:, error_class: nil, payment_provider: nil, metadata: {})
    return if message.blank?

    Enterprise::Billing::RecordBillingActivityService.new(
      account: @account,
      user: current_user,
      action: action,
      status: status,
      message: message,
      error_class: error_class,
      payment_provider: payment_provider,
      metadata: billing_activity_metadata.merge(metadata)
    ).perform
  rescue StandardError => e
    Rails.logger.error("[BillingActivityLog] #{e.class}: #{e.message}")
  end

  def log_billing_success(action, message, payment_provider: nil, metadata: {})
    log_billing_activity(
      action: action,
      message: message,
      status: 'success',
      payment_provider: payment_provider,
      metadata: metadata
    )
  end

  def log_billing_failure(action, message, error_class: nil, payment_provider: nil, metadata: {})
    log = log_billing_activity(
      action: action,
      message: message,
      status: 'failed',
      error_class: error_class,
      payment_provider: payment_provider,
      metadata: metadata
    )
    # Only alert on genuine exceptions (error_class present), not on plain
    # validation guards (e.g. a blank required field) that also route
    # through this same method.
    notify_super_admins_of_billing_failure(log) if log && error_class.present?
  end

  def notify_super_admins_of_billing_failure(log)
    return if BillingActivityLog.where.not(notified_at: nil).where(notified_at: BILLING_NOTIFICATION_THROTTLE.ago..).exists?

    log.update!(notified_at: Time.current)
    AdministratorNotifications::BillingAlertMailer.payment_failure(
      action: log.action,
      message: log.message,
      payment_provider: log.payment_provider,
      account: log.account
    ).deliver_later
  rescue StandardError => e
    Rails.logger.error("[BillingAlertMailer] failed to queue notification: #{e.class}: #{e.message}")
  end

  def billing_activity_metadata
    return {} unless respond_to?(:params) && params.present?

    params.permit(:plan_name, :country, :credits, :coupon_code, :currency, :cancel_at_cycle_end).to_h.compact
  end

  def render_payment_failure(action, message, error_class: nil, payment_provider: nil)
    log_billing_failure(
      action: action,
      message: message,
      error_class: error_class,
      payment_provider: payment_provider
    )
    render json: { error: message }, status: :unprocessable_entity
  end
end
