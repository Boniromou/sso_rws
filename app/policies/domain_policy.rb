class DomainPolicy < ApplicationPolicy
  policy_target :domain

  def initialize(system_user_context, record)
    super(system_user_context, record)
    @admin_property_use_only = true
  end

  def index?
    permitted?(:domain, :list)
  end

  def create?
    permitted?(:domain, :create)
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.all
      else
        scope.where("domains.id in (?)", DomainsCasino.where(:casino_id => system_user.active_casino_ids).select(:domain_id).uniq.pluck(:domain_id))
      end
    end
  end
end
