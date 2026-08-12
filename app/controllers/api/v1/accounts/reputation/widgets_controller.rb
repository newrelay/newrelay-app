class Api::V1::Accounts::Reputation::WidgetsController < Api::V1::Accounts::BaseController
  before_action :widget, only: [:update, :destroy]

  def index
    render json: current_account.reputation_widgets.order(created_at: :desc)
  end

  def create
    widget = current_account.reputation_widgets.create!(widget_params)
    render json: widget, status: :created
  end

  def update
    widget.update!(widget_params)
    render json: widget
  end

  def destroy
    widget.destroy!
    head :no_content
  end

  private

  def widget
    @widget ||= current_account.reputation_widgets.find(params[:id])
  end

  def widget_params
    params.require(:widget).permit(:name, :style, :min_rating, :active, :hide_watermark)
  end
end
