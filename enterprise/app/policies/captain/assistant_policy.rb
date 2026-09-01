class Captain::AssistantPolicy < ApplicationPolicy
  def index?
    allowed?
  end

  def show?
    allowed?
  end

  def stats?
    allowed?
  end

  def playground?
    allowed?
  end

  def tools?
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

  def sync?
    allowed?
  end

  private

  def allowed?
    @account_user.permissions.intersect?(%w[administrator captain_manage])
  end
end
