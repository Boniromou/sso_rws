module AuditLogsHelper
  def display_action_status(status_val)
    case status_val 
      when "success"
        "general.success"
      when "fail"
        "general.fail"
      else
        nil
    end
  end

  def display_target(target_name)
    case target_name
      when "system_user"
        "user.system_user"
      when "maintenance"
        "maintenance.title"
      else
        nil
    end
  end

  def display_action(action_name)
    case action_name
      when "lock"
        "user.lock"
      when "unlock"
        "user.unlock"
      when "edit_role"
        "user.edit_role"
      when "create"
        "maintenance.create"
      when "cancel"
        "maintenance.cancel"
      when "complete"
        "maintenance.complete"
      when "extend"
        "maintenance.extend"
      when "reschedule"
        "maintenance.reschedule"
      when "expire"
        "maintenance.expire"
      else
        nil
    end
  end
end
