module Enterprise::AutomationRule
  def self.prepended(base)
    base.class_eval do
      validate :enforce_automations_limit, on: :create
    end
  end

  def conditions_attributes
    super + %w[sla_policy_id]
  end

  def actions_attributes
    super + %w[add_sla]
  end

  private

  def enforce_automations_limit
    limit = account.limits['automations']
    return if limit.nil? # unlimited

    current_count = account.automation_rules.count
    if current_count >= limit.to_i
      errors.add(:base, "Automation rule limit of #{limit} has been reached for this account")
    end
  end
end
