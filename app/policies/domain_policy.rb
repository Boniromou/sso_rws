class DomainPolicy < ApplicationPolicy
  policy_target :domain

  def initialize(system_user_context, record)
    super(system_user_context, record)
    @admin_casino_use_only = true
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

  def index_domain_ldap?
    permitted?(:domain_ldap, :list)
  end

  def create_domain_ldap?
    permitted?(:domain_ldap, :create)
  end

  def update_domain_ldap?
    permitted?(:domain_ldap, :update)
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.all
      else
        scope.includes(:casinos).where("casinos.id in (?)", system_user.active_casino_ids)
      end
    end
  end
end
