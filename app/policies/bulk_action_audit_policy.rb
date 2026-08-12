class BulkActionAuditPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def index?
    @account_user.administrator? || @account_user.agent?
  end
end
