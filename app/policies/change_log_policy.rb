class ChangeLogPolicy < ApplicationPolicy
  def index?
    permitted?(:system_user, :list_edit_role_change_log)
  end

  def create_system_user?
    permitted?(:system_user, :list_create_user_change_log)
  end

  def inactive_system_user?
    permitted?(:system_user, :list_inactive_user_change_log)
  end

  def index_upload_role?
    permitted?(:role, :list_upload_change_log)
  end

  def index_create_domain_licensee?
    permitted?(:domain_licensee_mapping, :list_log)
  end

  def index_domain_ldap?
    permitted?(:domain_ldap, :list_log)
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.includes("target_casinos").all
      else
        scope.includes("target_casinos")
        .where("(change_logs.target_domain is null or change_logs.target_domain = ?)", system_user.domain.name)
        .where("(target_casinos.target_casino_id is null or target_casinos.target_casino_id in (?))", system_user.active_casino_ids)
      end
    end
  end
end
