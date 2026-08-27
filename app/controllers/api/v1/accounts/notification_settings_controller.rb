class Api::V1::Accounts::NotificationSettingsController < Api::V1::Accounts::BaseController
  before_action :set_user, :load_notification_setting

  def show; end

  def update
    update_flags
    @notification_setting.save!
    render action: 'show'
  end

  private

  def set_user
    @user = current_user
  end

  def load_notification_setting
    @notification_setting = @user.notification_settings.find_by(account_id: Current.account.id)
  end

  def notification_setting_params
    params.require(:notification_settings).permit(
      :quiet_hours_enabled,
      :quiet_hours_from_hour,
      :quiet_hours_from_minute,
      :quiet_hours_to_hour,
      :quiet_hours_to_minute,
      :quiet_hours_timezone,
      selected_email_flags: [],
      selected_push_flags: [],
      selected_quiet_hours_days: []
    )
  end

  def update_flags
    @notification_setting.selected_email_flags = notification_setting_params[:selected_email_flags]
    @notification_setting.selected_push_flags = notification_setting_params[:selected_push_flags]
    return if notification_setting_params[:quiet_hours_enabled].nil?

    @notification_setting.assign_attributes(
      notification_setting_params.slice(
        :quiet_hours_enabled,
        :quiet_hours_from_hour,
        :quiet_hours_from_minute,
        :quiet_hours_to_hour,
        :quiet_hours_to_minute,
        :quiet_hours_timezone
      )
    )
    @notification_setting.selected_quiet_hours_days = notification_setting_params[:selected_quiet_hours_days]
  end
end
