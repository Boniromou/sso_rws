class AuditLogPolicy < ApplicationPolicy
  def search?
    current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('audit_log', 'search')
  end
end
