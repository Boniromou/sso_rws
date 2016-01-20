class SystemUserPolicy < ApplicationPolicy
  def edit_roles?
    permitted?(:system_user, :grant_roles) && system_user.id != record.id && !record.is_root? && has_mutual_properties?
  end

  def update_roles?
    edit_roles?
  end

  def index?
    permitted?(:system_user, :show) # && same_group?
  end

  def show?
    permitted?(:system_user, :show) && has_mutual_properties?
  end

  def link?
    permitted?(:system_user, :show)
  end

  def has_mutual_properties?
    system_user.is_admin? || system_user.has_admin_property? || record.active_property_ids.any? && (record.active_property_ids - system_user.active_property_ids).blank?
  end

  #def same_group?
  #  system_user.is_admin? || system_user.has_admin_property? || same_scope?(record.active_property_ids)
  #end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_property?
        scope.all
      else
        users = scope.joins(:properties_system_users).where("properties_system_users.property_id in (?)", system_user.active_property_ids).select("DISTINCT(system_users.id), system_users.*")

        users.delete_if do |user|
          (user.active_property_ids - system_user.active_property_ids).any?
        end
      end
    end
  end
end
