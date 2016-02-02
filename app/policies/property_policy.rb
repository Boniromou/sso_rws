class PropertyPolicy < ApplicationPolicy
  def same_group?
    return true if system_user.is_admin? || system_user.has_admin_property?

    if record.blank? || record.is_a?(Symbol)
      same_scope?(request_property_id)
    else
      same_scope?(record.id)
    end
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_property?
        scope.all
      else
        scope.where("properties.id in (?)", system_user.property_ids)
      end
    end
  end
end
