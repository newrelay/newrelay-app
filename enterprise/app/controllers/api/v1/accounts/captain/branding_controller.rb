class Api::V1::Accounts::Captain::BrandingController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def create
    result = Captain::Llm::BrandColorGeneratorService.new(
      account: Current.account,
      url: params[:url],
      image: params[:image],
      prompt: params[:prompt]
    ).perform

    if result[:error].present?
      render json: { error: result[:error] }, status: result[:error_code] || :unprocessable_entity
    else
      render json: result, status: :ok
    end
  end

  private

  def check_authorization
    authorize(Current.account, :update?)
  end
end
