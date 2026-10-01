class NumberProvisioning::OrderPolicy < ApplicationPolicy
  def index?
    allowed?
  end

  def search?
    allowed?
  end

  def create?
    allowed?
  end

  def requirements?
    allowed?
  end

  def voice_agent?
    allowed?
  end

  def provisioning_config?
    allowed?
  end

  private

  def allowed?
    @account_user.administrator? && @account.feature_enabled?('phone_numbers')
  end
end
