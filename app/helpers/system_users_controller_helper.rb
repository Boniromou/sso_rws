module SystemUsersControllerHelper
  def system_user_status_format(status)
    return "user.active" if status
    return "user.inactive"
  end

  def change_status_button_name(status)
    return "user.lock" if status
    return "user.unlock"
  end

  def change_status_action_name(status)
    return "lock" if status
    return "unlock"
  end

  def roles_format(system_user)
    return "role.root_user" if system_user.is_root?
    return "general.na" if system_user.role_assignments.empty?
    return "role.#{system_user.roles[0].name}"
  end

  def allow_edit_roles?(system_user)
    policy(system_user).edit_roles? 
  end

  def current_role?(system_user, role_id)
    return false if system_user.role_assignments.blank?
    return true if system_user.role_assignments[0].role_id == role_id
    return false
  end
end
