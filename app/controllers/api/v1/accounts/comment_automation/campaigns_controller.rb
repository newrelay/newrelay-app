class Api::V1::Accounts::CommentAutomation::CampaignsController < Api::V1::Accounts::BaseController
  before_action :fetch_campaign, only: [:update, :destroy]
  before_action :check_authorization

  def index
    @campaigns = Current.account.comment_automation_campaigns.includes(:inbox, :triggers).order(created_at: :desc)
  end

  def create
    @campaign = Current.account.comment_automation_campaigns.new(campaign_params)
    @campaign.triggers.new(trigger_params.merge(account_id: Current.account.id)) if trigger_params.present?
    @campaign.save!
  end

  def update
    @campaign.update!(campaign_params)
    @campaign.triggers.first.update!(trigger_params) if trigger_params.present? && @campaign.triggers.first
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  private

  def check_authorization
    authorize(@campaign || CommentAutomation::Campaign)
  end

  def fetch_campaign
    @campaign = Current.account.comment_automation_campaigns.find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:name, :inbox_id, :post_id, :is_active)
  end

  def trigger_params
    return {} unless params[:trigger]

    params.require(:trigger).permit(:keyword, :match_type, :dm_text_body, public_replies: [])
  end
end
