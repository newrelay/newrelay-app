class Api::V1::Accounts::CommentAutomation::SocialAccountsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    render json: {
      payload: store.social_accounts,
      meta: { teamMembers: store.team_members, teams: store.teams }
    }
  end

  def create
    render json: store.connect(params[:platform] || params.dig(:social_account, :platform)), status: :created
  rescue CommentAutomation::MockAutoresponderStore::Error => e
    render_could_not_create_error(e.message)
  end

  def update
    account = store.update_social_account(params[:id], social_account_params.to_h)
    return render_not_found_error(I18n.t('comment_automation.mock.not_found')) unless account

    render json: account
  end

  def sync
    render json: { payload: store.sync }
  end

  private

  def check_authorization
    authorize(CommentAutomation::Campaign)
  end

  def store
    @store ||= CommentAutomation::MockAutoresponderStore.new(Current.account)
  end

  def social_account_params
    source = params[:social_account].presence || params
    source.permit(:assignedTeam, :accessLevel, assignedMembers: [:id, :name, :email, :avatar, :role])
  end
end
