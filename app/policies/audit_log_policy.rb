class AuditLogPolicy < ApplicationPolicy
  def search?
    current_system_user.is_admin? || current_system_user.has_permission?('audit_log', 'search')
  end
end
