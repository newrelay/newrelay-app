class Api::V1::Accounts::PipelinesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_pipeline, only: [:show, :update, :destroy]

  def index
    @pipelines = Pipelines::EnsureDefaultService.new(account: Current.account).perform
  end

  def show; end

  def create
    @pipeline = Current.account.pipelines.create!(pipeline_params)
  end

  def update
    @pipeline.update!(pipeline_params)
  end

  def destroy
    @pipeline.destroy!
    head :ok
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :position)
  end
end
