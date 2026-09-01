class Api::V1::Accounts::Reputation::ReportsController < Api::V1::Accounts::Reputation::BaseController
  # POST /api/v1/accounts/:account_id/reputation/reports
  def create
    report = current_account.reputation_reports.create!(config: report_config)
    render json: { token: report.token, share_url: share_url(report.token) }, status: :created
  end

  private

  def report_config
    params.permit(:report_type, :date_range, :layout, sections: []).to_h
  end

  def share_url(token)
    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/reputation/reports/#{token}"
  end
end
