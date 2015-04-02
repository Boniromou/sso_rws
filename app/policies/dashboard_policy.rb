class DashboardPolicy < Struct.new(:current_system_user, :dashboard)
  def user_management?
    SystemUserPolicy.new(current_system_user, SystemUser.new).index?
  end

  def audit_log?
    AuditLogPolicy.new(current_system_user, AuditLog.new).search?
  end
end
