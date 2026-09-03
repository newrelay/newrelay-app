class Api::V1::Accounts::CommentAutomation::MockCommentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def create
    result = CommentAutomation::PostMockCommentService.new(
      account: Current.account,
      text: params[:text],
      name: params[:name]
    ).perform

    render json: result, status: :created
  rescue CommentAutomation::PostMockCommentService::Error => e
    render_could_not_create_error(e.message)
  end

  private

  def check_authorization
    authorize(CommentAutomation::Campaign)
  end
end
