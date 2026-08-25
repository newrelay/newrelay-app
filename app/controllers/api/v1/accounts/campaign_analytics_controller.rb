class Api::V1::Accounts::CampaignAnalyticsController < Api::V1::Accounts::BaseController
  before_action :authorize_campaign_analytics

  def show
    result = Campaigns::AnalyticsService.new(
      account: Current.account,
      since: params[:since],
      until_time: params[:until],
      status: params[:status],
      inbox_id: params[:inbox_id]
    ).perform

    @summary = result[:summary]
    @campaigns = result[:campaigns]
    @filters = result[:filters]
  end

  private

  def authorize_campaign_analytics
    authorize(Campaign, :index?)
  end
end
