class SystemUserChangeLogPolicy < ApplicationPolicy
  def index?
    permitted?(:system_user, :list_change_log)
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.all
      else
        scope.where("system_user_change_logs.target_casino_id in (?)", system_user.active_casino_ids)
      end
    end
  end
end