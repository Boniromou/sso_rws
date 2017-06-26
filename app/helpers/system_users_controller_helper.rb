module SystemUsersControllerHelper
  def system_user_status_format(status)
    return "user.#{status}" if status
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

    id_names = []
    casino_id_names.each do |casino|
      id_names.push(Rigi::Format.symbolize_keys(casino))
    end

    rtn = ""
    id_names.each do |casino|
      rtn += " [#{casino[:name]}, #{casino[:id]}]," 
    end
    rtn = rtn.chomp(',') 
  end

end
