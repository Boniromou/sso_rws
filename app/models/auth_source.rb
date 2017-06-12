class AuthSource < ActiveRecord::Base
  attr_accessible :type
  DEFAULT_SRC = "Laxino LDAP"
  # self.inheritance_column = '_disable'
  # attr_accessible :id, :auth_type, :name, :host, :port, :account, :account_password, :base_dn, :encryption, :method, :search_scope, :admin_account, :admin_password

  has_many :system_users
  # validates_presence_of :name, :host, :port, :account, :account_password, :base_dn, :admin_account, :admin_password, :message => I18n.t("alert.invalid_params")
  # validates_uniqueness_of :name, :message => I18n.t("alert.ldap_duplicated")
  # validates_length_of :name, :maximum => 60, :message => I18n.t("alert.invalid_ldap_name")

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

  def self.insert(params)
    params = strip_whitespace(params)
    params[:auth_type] = AuthSourceLdap.to_s
    create!(params)
  end

  def self.edit(params)
    auth_source = find_by_id(params[:id])
    if auth_source
      auth_source.update_attributes!(strip_whitespace(params))
    else
      auth_source = insert(params)
    end
    auth_source
  end

  def self.strip_whitespace(params)
    Hash[params.collect{|k,v| [k, v.to_s.strip]}]
  end
end
