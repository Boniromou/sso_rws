class SystemUserPolicy < ApplicationPolicy
  def index?
    current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('system_user', 'list_system_user')
  end

  def lock?
    (current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('system_user', 'lock_system_user')) && current_system_user.id != record.id && !record.is_root?
  end

  def unlock?
    (current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('system_user', 'unlock_system_user')) && current_system_user.id != record.id && !record.is_root?
  end

  def show?
    current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('system_user', 'list_system_user')
  end

  def edit_roles?
    (current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('system_user', 'grant_roles')) && current_system_user.id != record.id && !record.is_root?
  end

  def update_roles?
    edit_roles?
  end
end
