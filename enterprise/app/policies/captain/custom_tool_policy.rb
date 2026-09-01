class Captain::CustomToolPolicy < ApplicationPolicy
  def index?
    readable?
  end

  def show?
    readable?
  end

  def create?
    manageable?
  end

  def test?
    manageable?
  end

  def update?
    manageable?
  end

  def destroy?
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
