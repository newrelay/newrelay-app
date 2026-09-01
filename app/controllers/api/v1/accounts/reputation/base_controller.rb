class Api::V1::Accounts::Reputation::BaseController < Api::V1::Accounts::BaseController
  before_action :authorize_reputation_access!

  private

  def authorize_reputation_access!
    return if Current.account_user.permissions.intersect?(%w[administrator agent reputation_manage])

    raise Pundit::NotAuthorizedError
  end
end
