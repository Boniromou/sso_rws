class LoginHistoryPolicy < ApplicationPolicy
  policy_target :login_history
  map_policy :list?

  class Scope < Scope
    def resolve
      if system_user.is_admin? || system_user.has_admin_casino?
        scope.all
      else
        histories = scope.all
        system_user_casinos = system_user.active_casino_ids
        histories.delete_if do |historiy|
          (historiy.detail['casino_ids'].to_a - system_user_casinos).any?
        end
      end
    end
  end
end