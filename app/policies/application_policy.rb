class ApplicationPolicy
  attr_reader :current_system_user, :record

  def initialize(current_system_user, record)
    @current_system_user = current_system_user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(current_system_user, record.class)
  end

  class Scope
    attr_reader :current_system_user, :scope

    def initialize(current_system_user, scope)
      @current_system_user = current_system_user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end

