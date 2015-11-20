class RolePolicy < ApplicationPolicy
  policy_target :role
  map_policy :index?, :action_name => :list
  map_policy :link?, :delegate_policies => [:index?]
end
