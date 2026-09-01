class Captain::AssistantPolicy < ApplicationPolicy
  def index?
    readable?
  end

  def show?
    readable?
  end

  def stats?
    readable?
  end

  def playground?
    readable?
  end

  def tools?
    manageable?
  end

  def create?
    manageable?
  end

  def update?
    manageable?
  end

  def destroy?
    manageable?
  end

  def sync?
    manageable?
  end

  private

  def readable?
    @account_user.permissions.intersect?(%w[administrator agent captain_manage])
  end

  def manageable?
    @account_user.permissions.intersect?(%w[administrator captain_manage])
  end
end
