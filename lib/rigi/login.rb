module Rigi
  module Login
    extend self

    EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

    #
    # triggle ldap call, update system_user profile, and then write role permission data to cache
    # when failed, error code indicates the reason
    # e.g.
    #   authenticate('portal.admin@mo.laxino.com')
    # => SystemUser with username as 'portal.admin'
    #
    #   authenticate('licuser01@mo.laxino.com')
    # => raise InvalidLogin.new('alert.account_no_role')
    #
    def authenticate!(username_with_domain, password, app_name)
      auth_source = AuthSource.first
      login = extract_login_name(username_with_domain)

      if login.nil?
        Rails.logger.error "SystemUser[username=#{username_with_domain}] illegal login name format"
        raise InvalidLogin.new("alert.invalid_login")
      end

      domain = Domain.where(:name => login[:domain]).first
      if domain.nil?
        Rails.logger.error "SystemUser[username=#{username_with_domain}] Login failed. Not a registered account with existing domain"
        raise InvalidLogin.new("alert.invalid_login")
      end

      system_user = SystemUser.where(:username => login[:username], :domain_id => domain.id, :auth_source_id => auth_source.id).first

      if system_user.nil?
        Rails.logger.error "SystemUser[username=#{username_with_domain}] Login failed. Not a registered account"
        raise InvalidLogin.new("alert.invalid_login")
      end

      auth_source = auth_source.becomes(auth_source.auth_type.constantize)

      if auth_source.authenticate(username_with_domain, password)
        system_user.update_ad_profile
        validate_role_status!(system_user, app_name)
        validate_account_status!(system_user)
        validate_account_casinos!(system_user)
        system_user.cache_info(app_name)
      else
        Rails.logger.error "SystemUser[username=#{username_with_domain}] Login failed. Authentication failed"
        raise InvalidLogin.new("alert.invalid_login")
      end

      system_user
    end

    def extract_login_name(login_name)
      match_data = EMAIL_REGEX.match(login_name)

      if match_data
        username, domain = login_name.split('@')
        { :username => username, :domain => domain }
      end
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

    def validate_account_casinos!(system_user)
      if !system_user.is_admin? && system_user.active_casino_ids.blank?
        Rails.logger.error "SystemUser[username=#{system_user.username}] Login failed. The account has no casinos"
        raise InvalidLogin.new("alert.account_no_casino")
      end
    end
  end
end