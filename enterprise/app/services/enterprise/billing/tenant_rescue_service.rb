class Enterprise::Billing::TenantRescueService
  def call(orphaned_t3_account)
    # 1. Detach from parent reseller
    orphaned_t3_account.update!(parent_id: nil)

    # 2. Promote to a direct platform subscription with manual review flag
    subscription = Subscription.find_or_initialize_by(account: orphaned_t3_account)
    subscription.update!(
      relationship_type: 'platform',
      connected_account_id: nil,
      status: 'active', # Keep service running
      plan_name: 'Platform Promoted Plan',
      stripe_price_id: nil,
      stripe_product_id: nil
    )

    # Flag for Super Admin review/policy check
    orphaned_t3_account.update!(
      custom_attributes: (orphaned_t3_account.custom_attributes || {}).merge(
        'orphaned_promotion_review_pending' => true
      )
    )

    # 3. Notify the T3 account administrators about the change
    begin
      AdministratorNotifications::AccountNotificationMailer.with(account: orphaned_t3_account).tenant_rescued(orphaned_t3_account).deliver_later
    rescue StandardError => e
      Rails.logger.error("Failed to deliver tenant rescue notification: #{e.message}")
    end

    true
  end
end
