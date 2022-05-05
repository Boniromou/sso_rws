class RolePolicy < ApplicationPolicy
  policy_target :role
  map_policy :upload?
  map_policy :index?, :action_name => :list
  map_policy :link?, :delegate_policies => [:index?]

  def allow_to_assign?
    system_user.is_admin? || system_user.role_in_app.role_type.name == ADMIN_ROLE_TYPE_NAME || system_user.role_in_app.role_type_id == record.role_type_id
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.role_in_app.role_type.name == ADMIN_ROLE_TYPE_NAME
        scope.all
      else
        scope.where("roles.role_type_id = ?", system_user.role_in_app.role_type_id)
      end
    end
  end
end
