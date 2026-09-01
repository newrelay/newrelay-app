class PipelinePolicy < ApplicationPolicy
  def index?
    allowed?
  end

  def show?
    allowed?
  end

  def create?
    allowed?
  end

  def update?
    allowed?
  end

  def destroy?
    @account_user.permissions.intersect?(%w[administrator crm_manage])
  end

  private

  def allowed?
    @account_user.permissions.intersect?(%w[administrator agent crm_manage])
  end
end
