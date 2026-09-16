module Admin::AuditLogsHelper
  def admin_audit_subject_label(subject)
    case subject
    when Band then subject.name
    when Album, Post then subject.title
    when Comment then subject.body.truncate(60)
    end
  end
end
