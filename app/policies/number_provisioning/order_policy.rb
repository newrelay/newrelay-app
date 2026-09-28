class NumberProvisioning::OrderPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def search?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end
end
