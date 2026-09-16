class Admin::AuditLogsController < Admin::BaseController
  def index
    @audit_logs = AdminActionLog.includes(:actor, :subject).order(created_at: :desc)
  end
end
