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

  def provisioning_config?
    @account_user.administrator?
  end
end
