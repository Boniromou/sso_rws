module Rigi
  module Login
    extend self

    #
    # triggle ldap call, update system_user profile, and then write role permission data to cache
    # when failed, error code indicates the reason
    # e.g. 
    #   authenticate('portal.admin')
    # => SystemUser with username as 'portal.admin'
    #
    #   authenticate('licuser01')
    # => raise InvalidLogin.new('alert.account_no_role')
    #
    def authenticate!(username, password, app_name)
      auth_source = AuthSource.find_by_id(AUTH_SOURCE_ID)
      system_user = SystemUser.where(:username => username, :auth_source_id => auth_source.id).first

      if system_user.nil?
        Rails.logger.error "SystemUser[username=#{username}] Login failed. Not a registered account"
        raise InvalidLogin.new("alert.invalid_login")
      end

      validate_role_status!(system_user, app_name)
      auth_source = auth_source.becomes(auth_source.auth_type.constantize)

      if auth_source.authenticate(system_user.login, password)
        system_user.update_ad_profile
        validate_account_status!(system_user)
        validate_account_properties!(system_user)
        system_user.cache_info(APP_NAME)
      else
        Rails.logger.error "SystemUser[username=#{username}] Login failed. Authentication failed"
        raise InvalidLogin.new("alert.invalid_login")
      end

      system_user
    end

    def validate_role_status!(system_user, app_name)
      unless system_user.is_admin? || system_user.role_in_app(app_name)
        Rails.logger.error "SystemUser[username=#{system_user.username}] Login failed. No role assigned"
        raise InvalidLogin.new("alert.account_no_role")
      end
    end

    def validate_account_status!(system_user)
      if !system_user.activated?
        Rails.logger.error "SystemUser[username=#{system_user.username}] Login failed. Inactive_account"
        raise InvalidLogin.new("alert.inactive_account")
      end
    end

    def validate_account_properties!(system_user)
      if !system_user.is_admin? && system_user.active_property_ids.blank?
        Rails.logger.error "SystemUser[username=#{system_user.username}] Login failed. The account has no properties"
        raise InvalidLogin.new("alert.account_no_property")
      end
    end
  end
end