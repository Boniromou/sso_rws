class DomainCasinoPolicy < ApplicationPolicy
  Target_name = :domain_casino_mapping

  policy_target Target_name

  def index?
    permitted?(Target_name, :list)
  end

  def create?
    permitted?(Target_name, :create)
  end

  def inactive?
    permitted?(Target_name, :inactive)
  end

  def index_log?
    permitted?(Target_name, :list_log)
  end
end
