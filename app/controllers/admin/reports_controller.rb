class Admin::ReportsController < Admin::BaseController
  before_action :set_report, only: [ :resolve, :dismiss ]

  def index
    @reports = Report.includes(:reporter, :reportable).order(created_at: :desc)
  end

  def resolve
    @report.resolved!
    redirect_to admin_reports_path, notice: "Report resolved."
  end

  def dismiss
    @report.dismissed!
    redirect_to admin_reports_path, notice: "Report dismissed."
  end

  private

  def set_report
    @report = Report.find(params[:id])
  end
end
