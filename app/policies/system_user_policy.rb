class SystemUserPolicy < ApplicationPolicy
  def index?
    current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('SystemUser', 'index')
  end

  def lock?
    (current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('SystemUser', 'lock')) && current_system_user.id != record.id && !record.is_root?
  end

  def unlock?
    (current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('SystemUser', 'unlock')) && current_system_user.id != record.id && !record.is_root?
  end

  def show?
    current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('SystemUser', 'show')
  end

  def edit_roles?
    (current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('SystemUser', 'edit_roles')) && current_system_user.id != record.id && !record.is_root?
  end

  def update_roles?
    edit_roles?
  end
end
