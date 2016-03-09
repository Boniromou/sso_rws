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

  #def allow_edit_roles?(system_user)
  #  policy(system_user).edit_roles?
  #end

  def current_role?(system_user, role_id)
    return false if system_user.role_assignments.blank?
    return true if system_user.role_assignments.find_by_role_id(role_id)
    return false
  end

  def current_app?(system_user, app_id)
    #assigned_apps = system_user.app_system_users
    #if assigned_apps &&
    if system_user.app_system_users.find_by_app_id(app_id)
      true
    else
      false
    end
  end

  def casino_id_names_format(casino_id_names)
    return '' if casino_id_names.blank?
    rtn = "[#{casino_id_names.first[:name]}, #{casino_id_names.first[:id]}]"
    for i in 1...casino_id_names.length do
      rtn += ", [#{casino_id_names[i][:name]}, #{casino_id_names[i][:id]}]"
    end
    rtn
  end
end
