class Api::V1::Accounts::CommentAutomation::TemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_template, only: [:update, :destroy]
  before_action :check_authorization

  def index
    @templates = Current.account.comment_automation_templates.order(created_at: :desc)
  end

  def create
    @template = Current.account.comment_automation_templates.new(template_params)
    @template.save!
  end

  def update
    @template.update!(template_params)
  end

  def destroy
    @template.destroy!
    head :ok
  end

  private

  def check_authorization
    authorize(@template || CommentAutomation::Template)
  end

  def fetch_template
    @template = Current.account.comment_automation_templates.find(params[:id])
  end

  def template_params
    params.require(:template).permit(:name, :template_type, :dm_text_body, :favorite, public_replies: [])
  end
end
