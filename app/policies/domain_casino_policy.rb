class DomainCasinoPolicy < ApplicationPolicy
  policy_target :domain_casino_mapping

  def index?
    permitted?(target_name, :list)
  end

  def create?
    permitted?(target_name, :create)
  end

  def destroy?
    permitted?(target_name, :inactive)
  end

  def index_log?
    permitted?(target_name, :list_log)
  end
end
