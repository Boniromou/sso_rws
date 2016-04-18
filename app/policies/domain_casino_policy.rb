class DomainCasinoPolicy < ApplicationPolicy
  @@target_name = :domain_casino_mapping

  policy_target @@target_name

  def initialize(system_user_context, record)
    super(system_user_context, record)
    @admin_casino_use_only = true
  end

  def index?
    permitted?(@@target_name, :list)
  end

  def create?
    permitted?(@@target_name, :create)
  end

  def inactive?
    permitted?(@@target_name, :inactive)
  end

  def index_log?
    permitted?(@@target_name, :list_log)
  end
end
