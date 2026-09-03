class Api::V1::Accounts::CommentAutomation::MockConnectionsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def create
    inbox = CommentAutomation::ConnectMockChannelService.new(
      account: Current.account,
      url: params[:url],
      name: params[:name]
    ).perform

    render json: { id: inbox.id, name: inbox.name, channel_type: inbox.channel_type }, status: :created
  rescue CommentAutomation::ConnectMockChannelService::Error => e
    render_could_not_create_error(e.message)
  end

  private

  def check_authorization
    authorize(CommentAutomation::Campaign)
  end
end
