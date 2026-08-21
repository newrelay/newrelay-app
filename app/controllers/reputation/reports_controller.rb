# Public — renders a shared reputation report by token (no auth). Printable HTML = the "PDF".
# GET /reputation/reports/:token
class Reputation::ReportsController < ApplicationController
  layout false

  def show
    @report = Reputation::Report.find_by!(token: params[:token])
    @config = @report.config || {}
    @sections = Array(@config['sections']).presence ||
                ['Reputation Score', 'Average Rating', 'Review Trend', 'Platform Breakdown']
    @summary = Reputation::SummaryBuilder.new(@report.account).as_json
  rescue ActiveRecord::RecordNotFound
    render plain: 'Report not found', status: :not_found
  end
end
