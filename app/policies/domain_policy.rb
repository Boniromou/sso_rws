class DomainPolicy < ApplicationPolicy
  def index?
    permitted?(:domain, :list)
  end

  def create?
    permitted?(:domain, :create)
  end
end