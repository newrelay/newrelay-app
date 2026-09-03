class Api::V1::Accounts::CommentAutomation::SettingsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def show
    render json: store.settings
  end

  def update
    render json: store.update_settings(settings_params.to_h)
  end

  private

  def check_authorization
    authorize(CommentAutomation::Campaign)
  end

  def store
    @store ||= CommentAutomation::MockAutoresponderStore.new(Current.account)
  end

  def settings_params
    source = params[:setting].presence || params[:settings].presence || params
    source.permit!
  end
end
