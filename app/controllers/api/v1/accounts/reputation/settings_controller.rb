class Api::V1::Accounts::Reputation::SettingsController < Api::V1::Accounts::BaseController
  def show
    render json: { config: settings.config }
  end

  def update
    settings.update!(config: settings.config.merge(config_params))
    render json: { config: settings.config }
  end

  private

  def settings
    @settings ||= current_account.reputation_setting || current_account.build_reputation_setting
  end

  def config_params
    (params.permit(config: {})[:config] || {}).to_h
  end
end
