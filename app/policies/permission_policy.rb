class PermissionPolicy < ApplicationPolicy
  policy_target :permission
  map_policy :show?
end
