class AccountPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def cache_keys?
    @account_user.administrator? || @account_user.agent?
  end

  def limits?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    @account_user.administrator?
  end

  def update_active_at?
    true
  end

  def subscription?
    @account_user.administrator?
  end

  def checkout?
    @account_user.administrator?
  end

  def toggle_deletion?
    @account_user.administrator?
  end

  def topup_checkout?
    @account_user.administrator?
  end

  def cancel_subscription?
    @account_user.administrator?
  end

  def bypass_plan?
    @account_user.administrator?
  end

  def plan_checkout?
    @account_user.administrator?
  end

  def validate_coupon?
    @account_user.administrator?
  end

  def checkout_return?
    @account_user.administrator?
  end

  def plans?
    @account_user.administrator?
  end

  def enterprise_inquiry?
    @account_user.administrator?
  end

  def cancel_enterprise_inquiry?
    @account_user.administrator?
  end

  def transactions?
    @account_user.administrator?
  end
end
