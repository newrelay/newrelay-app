class Api::V1::Accounts::ElevenlabsVoicesController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    render json: Twilio::ElevenlabsVoicesService.new(account: Current.account).list
  end

  def create
    voice = Twilio::ElevenlabsVoicesService.new(account: Current.account).enqueue(
      name: params[:name],
      clip: params[:clip],
      consent: ActiveModel::Type::Boolean.new.cast(params[:consent]),
      tone: params[:tone],
      persona: params[:persona]
    )
    render json: { id: voice.id, name: voice.name, status: voice.status }, status: :accepted
  rescue Twilio::ConnectElevenlabsService::Error => e
    render_could_not_create_error(e.message)
  end
end
