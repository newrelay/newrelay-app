class Captain::ScenarioPolicy < ApplicationPolicy
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
    allowed?
  end

  private

  def allowed?
    @account_user.permissions.intersect?(%w[administrator captain_manage])
  end
end
