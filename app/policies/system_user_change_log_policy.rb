class SystemUserChangeLogPolicy < ApplicationPolicy
  def index?
    #permitted?(:system_user, :show)
    true
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_property?
        scope.all
      else
        scope.where("system_user_change_logs.target_property_id in (?)", system_user.active_property_ids)
      end
    end
  end
end