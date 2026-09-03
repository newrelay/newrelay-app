class CommentAutomation::CampaignPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def show?
    index?
  end

  def destroy?
    @account_user.administrator?
  end

  def sync?
    update?
  end
end
