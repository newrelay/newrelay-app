class Enterprise::Billing::GracePeriodEnforcerJob < ApplicationJob
  queue_as :default

  def perform
    # Find active subscriptions that have an expired grace period
    expired_subscriptions = Subscription.active.where('grace_period_ends_at <= ?', Time.current)

    expired_subscriptions.find_each do |subscription|
      ActiveRecord::Base.transaction do
        # 1. Suspend the client account
        subscription.account.update!(status: :suspended)

        # 2. Update subscription status and clear the grace period column
        subscription.update!(
          status: 'suspended',
          grace_period_ends_at: nil
        )

        Rails.logger.info("Grace period expired. Suspended account: #{subscription.account_id}")
      end
    rescue => e
      Rails.logger.error("Failed to enforce grace period suspension for subscription #{subscription.id}: #{e.message}")
    end
  end
end
