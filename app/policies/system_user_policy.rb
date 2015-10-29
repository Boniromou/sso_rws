class SystemUserPolicy < ApplicationPolicy
  def index?
    current_system_user.is_admin? || current_system_user.has_permission?('system_user', 'show')
  end

  def lock?
    (current_system_user.is_admin? || current_system_user.has_permission?('system_user', 'lock')) && current_system_user.id != record.id && !record.is_root?
  end

  def unlock?
    (current_system_user.is_admin? || current_system_user.has_permission?('system_user', 'unlock')) && current_system_user.id != record.id && !record.is_root?
  end

  def show?
    current_system_user.is_admin? || current_system_user.has_permission?('system_user', 'show')
  end

  def edit_roles?
    (current_system_user.is_admin? || current_system_user.has_permission?('system_user', 'grant_roles')) && current_system_user.id != record.id && !record.is_root?
  end

  def update_roles?
    edit_roles?
  end
end
