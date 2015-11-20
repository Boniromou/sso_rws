require 'net/ldap'
require 'net/ldap/dn'
require 'timeout'

class AuthSourceLdap < AuthSource
  validates_presence_of :host, :port, :attr_login
  validates_length_of :name, :host, :maximum => 60, :allow_nil => true
  validates_length_of :account, :account_password, :base_dn, :filter, :maximum => 255, :allow_blank => true
  validates_length_of :attr_login, :attr_firstname, :attr_lastname, :attr_mail, :maximum => 30, :allow_nil => true
  validates_numericality_of :port, :only_integer => true
  validates_numericality_of :timeout, :only_integer => true, :allow_blank => true
#  validate :validate_filter

  #before_validation :strip_ldap_attributes

  def initialize(attributes=nil, *args)
    super
    self.port = 389 if self.port == 0
  end

  def authenticate(login, password)
    return false if login.blank? || password.blank?
    Rails.logger.info "[auth_source_id=#{self.id}]LDAP authenticating to #{self.name}...."
    ldap_con = initialize_ldap_con(login, password)
    ldap_con.bind ? true : false
  end

  def initialize_ldap_con(ldap_user, ldap_password)
    source_host = defined?(AUTH_SOURCE_HOST) ? AUTH_SOURCE_HOST : self.host
    options = { :host => source_host,
                :port => self.port,
                :encryption => nil,
                :auth => {
                  :method => :simple,
                  :username => ldap_user,
                  :password => ldap_password
                  }
                }
    Net::LDAP.new options
  end

  def get_domain
    dn_arr = self.base_dn.split(',')
    dn_arr.first.split('=')[1]
  end
end
