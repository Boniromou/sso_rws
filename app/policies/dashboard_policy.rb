class DashboardPolicy < Struct.new(:current_system_user, :dashboard)
  def audit_log?
    AuditLogPolicy.new(current_system_user, AuditLog.new).search?
  end
end
