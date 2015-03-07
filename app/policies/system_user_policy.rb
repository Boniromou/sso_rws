class SystemUserPolicy < ApplicationPolicy
  def index?
    p "checking system user index"
    current_system_user.admin? || current_system_user.role_in_app.has_permission?('index')
  end

  def lock?
    p "checking system user lock"
    (current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('lock')) && current_system_user.id != record.id && !record.is_root?
  end

  def unlock?
    p "checking system user unlock"
    (current_system_user.is_admin? || current_system_user.role_in_app.has_permission?('unlock')) && current_system_user.id != record.id && !record.is_root?
  end
end
