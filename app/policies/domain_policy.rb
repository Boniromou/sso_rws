class DomainPolicy < ApplicationPolicy
  policy_target :domain

  def initialize(system_user_context, record)
    super(system_user_context, record)
    @admin_casino_use_only = true
  end

  def index?
    permitted?(:domain, :list)
  end

  def create?
    permitted?(:domain, :create)
  end

  def index_domain_licensee?
    permitted?(:domain_licensee_mapping, :list)
  end

  def create_domain_licensee?
    permitted?(:domain_licensee_mapping, :create)
  end

  def delete_domain_licensee?
    permitted?(:domain_licensee_mapping, :delete)
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.all
      else
        scope.where("domains.licensee_id in (?)", Casino.where(:id => system_user.active_casino_ids).select(:licensee_id).uniq.pluck(:licensee_id))
      end
    end
  end
end
