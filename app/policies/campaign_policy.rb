class CampaignPolicy < ApplicationPolicy
  def index?
    allowed?
  end

  def update?
    allowed?
  end

  def show?
    allowed?
  end

  def create?
    allowed?
  end

  def destroy?
    allowed?
  end

  private

  def allowed?
    @account_user.permissions.intersect?(%w[administrator marketing_manage])
  end
end
