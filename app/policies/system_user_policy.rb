class SystemUserPolicy < ApplicationPolicy
  def edit_roles?
    permitted?(:system_user, :grant_roles) && system_user.id != record.id && !record.is_root? && has_mutual_casinos?
  end

  def update_roles?
    edit_roles?
  end

  def new?
    create?
  end

  def create?
    permitted?(:system_user, :create)
  end

  def index?
    permitted?(:system_user, :show) # && same_group?
  end

  def show?
    permitted?(:system_user, :show) && has_mutual_casinos?
  end

  def link?
    permitted?(:system_user, :show)
  end

  def has_mutual_casinos?
    system_user.is_admin? || system_user.has_admin_casino? || record.active_casino_ids.any? && (record.active_casino_ids - system_user.active_casino_ids).blank?
  end

  #def same_group?
  #  system_user.is_admin? || system_user.has_admin_casino? || same_scope?(record.active_casino_ids)
  #end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.all
      else
        users = scope.joins(:casinos_system_users).where("casinos_system_users.casino_id in (?)", system_user.active_casino_ids).group("system_users.id").all

        users.delete_if do |user|
          if user.activated?
            (user.active_casino_ids - system_user.active_casino_ids).any?
          else
            (user.casino_ids - system_user.active_casino_ids).any?
          end
        end
      end
    end
  end
end
