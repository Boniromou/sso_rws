class CasinoPolicy < ApplicationPolicy
  def same_group?
    return true if system_user.is_admin? || system_user.has_admin_casino?

    if record.blank? || record.is_a?(Symbol)
      same_scope?(request_casino_id)
    else
      same_scope?(record.id)
    end
  end

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.all
      else
        scope.where("casinos.id in (?)", system_user.casino_ids)
      end
    end
  end
end
