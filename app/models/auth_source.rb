class AuthSource < ActiveRecord::Base
  DEFAULT_SRC = "Laxino LDAP"

  has_many :system_users
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 60
  attr_accessible :auth_type, :name, :host, :port, :account, :account_password, :base_dn, :attr_login, :admin_account, :admin_password

  def authenticate(login, password)
    raise NotImplementedError
  end
=begin
  # Try to authenticate a user not yet registered against available sources
  def self.authenticate(login, password)
    AuthSource.where(:onthefly_register => true).each do |source|
      begin
        logger.debug "Authenticating '#{login}' against '#{source.name}'" if logger && logger.debug?
        result = source.authenticate(login, password)
      rescue => e
        logger.error "Error during authentication: #{e.message}"
        attrs = nil
      end
      return result if result
    end
    return nil
  end
=end
  def self.get_default_auth_source
    AuthSource.find_by_name(DEFAULT_SRC)
  end
end
