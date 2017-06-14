require 'net/ldap'
require 'devise/strategies/authenticatable'
#require 'authentication/ldap'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def valid?
        auth_token || user_info
      end

      def authenticate!
        system_user = SystemUser.find_by_id(user_info[:system_user][:id])
        success!(system_user)
        clear_cookie_and_cache
      end

      def auth_token
        cookies[:auth_token]
      end

      def user_info
        result = Rails.cache.read(auth_token)
      end

      def clear_cookie_and_cache
        Rails.cache.delete(auth_token)
        cookies.delete(:auth_token, domain: :all)
      end
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
#Devise.add_module :ldap_authenticatable, :strategy => true
