class AuditLogPolicy < ApplicationPolicy
  policy_target :audit_log
  map_policy :search?
  map_policy :link?, :delegate_policies => [:search?]

  def initialize(system_user_context, record)
    super(system_user_context, record)
    @admin_casino_use_only = true
  end
end
