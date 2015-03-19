class AuditLogPolicy < ApplicationPolicy
  def search?
    p "checking audit log search"
    current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('AuditLog', 'search')
  end
end
