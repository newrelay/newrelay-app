class Api::V1::Accounts::CommentAutomation::ResponseControlsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    render json: {
      payload: {
        posts: store.posts,
        dms: store.dms,
        defaults: store.defaults,
        automations: store.automations
      }
    }
  end

  def update
    item = if params[:id] == 'defaults'
             store.update_defaults(defaults_params.to_h)
           else
             store.update_response_control(params[:id], response_control_params.to_h)
           end
    return render_not_found_error(I18n.t('comment_automation.mock.not_found')) unless item

    render json: item
  end

  private

  def check_authorization
    authorize(CommentAutomation::Campaign)
  end

  def store
    @store ||= CommentAutomation::MockAutoresponderStore.new(Current.account)
  end

  def response_control_params
    source = params[:response_control].presence || params
    source.permit(:enabled, :overridden, :automation,
                  comments: [:enabled, :overridden, :automation],
                  dms: [:enabled, :overridden, :automation])
  end

  def defaults_params
    source = params[:response_control].presence || params
    source.permit(:comments, :dms)
  end
end
