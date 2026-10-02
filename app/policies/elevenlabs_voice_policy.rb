class ElevenlabsVoicePolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def create?
    index?
  end
end
