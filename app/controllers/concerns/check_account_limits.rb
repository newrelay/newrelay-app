module CheckAccountLimits
  extend ActiveSupport::Concern

  included do
    before_action :enforce_account_limits!, only: [:create, :bulk_create]
  end

  private

  def enforce_account_limits!
    # Map the controller name to the corresponding resource limit key
    limit_key = case controller_name
                when 'agents', 'account_users'
                  'agents'
                when 'contacts'
                  'contacts'
                when 'conversations'
                  'conversations'
                when 'automation_rules'
                  'automations'
                end

    return unless limit_key

    account_context = Current.account || @account
    return unless account_context

    # Retrieve the configured limit for this account (nil means unlimited)
    limit_value = account_context.limits[limit_key]
    return if limit_value.blank?

    # Count the current usage of the resource
    current_count = current_resource_count_for_limit(limit_key, account_context)

    # If this is a bulk create action, add the incoming count
    incoming_count = 1
    incoming_count = params[:emails].length if action_name == 'bulk_create' && params[:emails].is_a?(Array)

    if (current_count + incoming_count) > limit_value.to_i
      render_payment_required("Account #{limit_key} limit exceeded. Please upgrade your plan.")
    end
  end

  def current_resource_count_for_limit(limit_key, account_context)
    case limit_key
    when 'agents'
      account_context.agents.count
    when 'contacts'
      account_context.contacts.count
    when 'conversations'
      account_context.conversations.count
    when 'automations'
      account_context.automation_rules.count
    else
      0
    end
  end
end
