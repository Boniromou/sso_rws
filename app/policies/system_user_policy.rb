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
    permitted?(:system_user, :show)
  end

  def show?
    permitted?(:system_user, :show) && has_mutual_casinos?
  end

  def link?
    permitted?(:system_user, :show)
  end

  def has_mutual_casinos?
    system_user.is_admin? || system_user.has_admin_casino? || record.pending? || (record.activated? && (record.active_casino_ids - system_user.active_casino_ids).blank?)
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.includes(:active_casinos).all
      else
        domain_ids = system_user.casinos.first.licensee.domains.map(&:id)
        users = scope.includes(:active_casinos, :casinos).where(domain_id: domain_ids).all
        users.delete_if do |user|
          if user.activated?
            (user.active_casino_ids - system_user.active_casino_ids).any?
          elsif user.inactived?
            (user.all_casino_ids - system_user.active_casino_ids).any?
          end
        end
      end
    end
  end
end
