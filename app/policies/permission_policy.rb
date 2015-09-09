class PermissionPolicy < ApplicationPolicy
  def show?
    current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('permission', 'show')
  end
end
