require 'net/ldap'
require 'devise/strategies/authenticatable'
#require 'authentication/ldap'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def valid?
        username || password
      end

      def authenticate!
        system_user = Rigi::Login.authenticate!(username, password, APP_NAME)
        success!(system_user)
      rescue Rigi::InvalidLogin => e
        fail!(e.error_message)
      end

      def username
        if params[:system_user]
          return params[:system_user][:username]
        end
        return nil
      end

      def password
        if params[:system_user]
          return params[:system_user][:password]
        end
        return nil
      end
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
#Devise.add_module :ldap_authenticatable, :strategy => true
