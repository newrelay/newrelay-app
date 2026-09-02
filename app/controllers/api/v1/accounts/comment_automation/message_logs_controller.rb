class Api::V1::Accounts::CommentAutomation::MessageLogsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    # ponytail: no pagination UI yet, cap the result set; add cursor pagination if this grows past a page.
    @message_logs = Current.account.comment_automation_message_logs
                           .includes(:contact, :inbox, trigger: :campaign)
                           .order(created_at: :desc)
                           .limit(200)
  end

  private

  def check_authorization
    authorize(CommentAutomation::MessageLog)
  end
end
