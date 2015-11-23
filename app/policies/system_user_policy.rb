class SystemUserPolicy < ApplicationPolicy
  def edit_roles?
    permitted?(:system_user, :show) && system_user.id != record.id && !record.is_root? && same_group?
  end

  def update_roles?
    edit_roles?
  end

  def index?
    permitted?(:system_user, :show) # && same_group?
  end

  def show?
    permitted?(:system_user, :show) && same_group?
  end

  def link?
    permitted?(:system_user, :show)
  end

  def same_group?
    system_user.is_internal? || same_scope?(record.active_property_ids)
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.is_internal? || system_user.active_property_ids.include?(INTERNAL_PROPERTY_ID)
        scope.all
      else
        scope.joins(:properties_system_users).where("properties_system_users.property_id in (?) AND system_users.auth_source_id = ?", system_user.active_property_ids, AUTH_SOURCE_ID)
      end
    end
  end
end
