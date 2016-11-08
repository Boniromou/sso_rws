class ChangeLogPolicy < ApplicationPolicy
  def index_create_domain_casino?
    permitted?(:domain_casino_mapping, :list_log)
  end

  def index?
    permitted?(:system_user, :list_edit_role_change_log)
  end

  def create_system_user?
    permitted?(:system_user, :list_create_user_change_log)
  end

  def index_create_domain_licensee?
    permitted?(:domain_licensee_mapping, :list_log)
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.all
      else
        scope.includes("target_casinos").where("target_casinos.target_casino_id in (?)", system_user.active_casino_ids)
      end
    end
  end
end