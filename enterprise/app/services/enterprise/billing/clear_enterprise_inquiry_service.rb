# Removes a pending Enterprise sales inquiry and optionally clears a stale
# unpaid Enterprise checkout subscription so the account can pick self-serve plans.
class Enterprise::Billing::ClearEnterpriseInquiryService
  PENDING_CHECKOUT_STATUSES = %w[created authenticated pending incomplete].freeze

  pattr_initialize [:account!, { cancel_pending_checkout: true, remove_inquiry: true }]

  def perform
    cleared_inquiry = remove_inquiry && clear_inquiry!
    cleared_checkout = cancel_pending_checkout && clear_pending_enterprise_checkout!
    cleared_inquiry || cleared_checkout
  end

  def clear_inquiry!
    attrs = stored_custom_attributes
    return false if attrs['enterprise_inquiry'].blank?

    attrs = attrs.dup
    attrs.delete('enterprise_inquiry')
    account.update_column(:custom_attributes, attrs)
    true
  end

  private

  def stored_custom_attributes
    account.read_attribute(:custom_attributes) || {}
  end

  def clear_pending_enterprise_checkout!
    subscription = account.subscription
    return false if subscription.blank?
    return false if subscription.active?
    return false unless subscription.plan_name == Enterprise::Billing::CloudPlans::ENTERPRISE_PLAN
    return false unless PENDING_CHECKOUT_STATUSES.include?(subscription.status)

    subscription.update!(
      status: 'canceled',
      grace_period_ends_at: nil
    )
    true
  end
end
