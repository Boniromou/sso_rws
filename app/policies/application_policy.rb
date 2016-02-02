class ApplicationPolicy
  include Rigi::PunditHelper::Policy
  attr_reader :system_user, :record, :request_property_id, :admin_property_use_only

  def initialize(system_user_context, record)
    @system_user = system_user_context.system_user
    @request_property_id = system_user_context.request_property_id
    @record = record
    @admin_property_use_only ||= false
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
    Pundit.policy_scope!(system_user, record.class)
  end

  class Scope
    attr_reader :system_user, :scope

    def initialize(system_user_context, scope)
      @system_user = system_user_context.system_user
      @scope = scope
    end

    def resolve
      scope
    end
  end

  protected
  def permitted?(target_name, action_names)
    return true if @system_user.is_admin?
    role_has_permission = found_permission?(@system_user.id, target_name, action_names)
    return false if @admin_property_use_only && !system_user.has_admin_property?

    role_has_permission
  end
end

