class NumberProvisioning::OrderPolicy < ApplicationPolicy
  def search?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end
end
