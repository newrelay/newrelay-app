class CompanyPolicy < ApplicationPolicy
  def index?
    allowed?
  end

  def search?
    allowed?
  end

  def show?
    allowed?
  end

  def create?
    allowed?
  end

  def import?
    allowed?
  end

  def update?
    allowed?
  end

  def avatar?
    update?
  end

  def destroy_custom_attributes?
    update?
  end

  def destroy?
    allowed?
  end

  private

  def allowed?
    @account_user.permissions.intersect?(%w[administrator company_manage])
  end
end
