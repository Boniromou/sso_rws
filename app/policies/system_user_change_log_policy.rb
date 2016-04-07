class SystemUserChangeLogPolicy < ChangeLogPolicy
  def index?
    permitted?(:system_user, :list_change_log)
  end
end