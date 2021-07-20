require 'net/ldap'
require 'devise/strategies/authenticatable'
#require 'authentication/ldap'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def valid?
        auth_token && user_info
      end

      def authenticate!
        user = user_info
        Rails.logger.info "token info: #{user}"
        system_user = SystemUser.find(user['id'])
        success!(system_user)
        rewrite_cookie
      end

      def auth_token
        cookies[:user_management_auth_token]
      end

      def user_info
        JWT.decode(auth_token, 'test_key', true)[0] if auth_token
      rescue
        nil
      end

      def rewrite_cookie
        cookies.delete(:user_management_token_info, domain: :all)
        cookies[:user_management_token_info] = { value: auth_token, domain: :all }
        cookies.delete(:user_management_auth_token, domain: :all)
      end
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
#Devise.add_module :ldap_authenticatable, :strategy => true
