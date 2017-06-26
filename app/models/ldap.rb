require 'net/ldap'
require 'net/ldap/dn'
require 'timeout'
class Ldap < AuthSource
  DISABLED_ACCOUNT_KEY = 'Disabled Accounts'
  MATCH_PATTERN_REGEXP = /CN=\d+casinoid/

  def get_url
    "/ldap/new"
  end

  def login!(username, password, app_name)
    valid_before_login!(username)
    system_user = SystemUser.find_by_username_with_domain(username)
    ldap_login!(system_user.domain.auth_source_detail, username, password)
    user_profile = retrieve_user_profile(system_user.domain.auth_source_detail, username, system_user.domain.get_casino_ids)
    authenticate!(username, app_name, user_profile[:status], user_profile[:casino_ids])
  end

  def create_ldap_user!(username, domain)
    domain_obj = Domain.where(:name => domain).first
    profile = retrieve_and_check_user_profile!(domain_obj.auth_source_detail, "#{username}@#{domain}", domain_obj.get_casino_ids)
    SystemUser.register!(username, domain, profile[:casino_ids])
  end

  def retrieve_user_profile(auth_source_detail, username_with_domain, casino_ids)
    ldap = initialize_ldap_con(auth_source_detail, nil, nil)
    search_filter = Net::LDAP::Filter.eq("userPrincipalName", "#{username_with_domain}")
    ldap_entry = ldap.search(:base => auth_source_detail['data']['base_dn'], :filter => search_filter, :return_result => true, :scope => auth_source_detail['data']['search_scope'] || Net::LDAP::SearchScope_WholeSubtree).first
    if ldap_entry.blank?
      Rails.logger.info "[username=#{username_with_domain}][filter_groups=#{casino_ids}] account is not in Ldap server "
      return {}
    end
    
    dnames = ldap_entry[:distinguishedName]
    memberofs = ldap_entry[:memberOf]
    is_disable_account, is_admin_group = false, false
    groups = []
    Rails.logger.info "Ldap server response: distinguishedName => #{dnames}, memberOf => #{memberofs}"

    is_disable_account = dnames.any? { |dn| dn.include?(DISABLED_ACCOUNT_KEY) }
    memberofs.each do |memberof|
      casino_ids.each do |filter|
        groups << filter.to_i if memberof_has_key?(memberof, MATCH_PATTERN_REGEXP, filter.to_s)
      end
    end

    status = is_disable_account ? SystemUser::INACTIVE : SystemUser::ACTIVE
    res = { :status => status, :casino_ids => groups.uniq }
    Rails.logger.info "[username=#{username_with_domain}][filter_groups=#{casino_ids}] account result => #{res.inspect}"
    res
  end

  private
  def valid_before_login!(username)
    system_user = SystemUser.find_by_username_with_domain(username)
    if system_user.nil?
      Rails.logger.error "SystemUser[username=#{username}] Login failed. Not a registered account"
      raise Rigi::InvalidLogin.new("alert.invalid_login")
    end
    auth_source_detail = system_user.domain.auth_source_detail
    if auth_source_detail.nil?
      Rails.logger.error "SystemUser[username=#{username}] Login failed. invalid domain ldap mapping"
      raise Rigi::InvalidLogin.new("alert.invalid_ldap_mapping")
    end
  end

  def retrieve_and_check_user_profile!(auth_source_detail, username_with_domain, casino_ids)
    profile = retrieve_user_profile(auth_source_detail, username_with_domain, casino_ids)
    raise Rigi::AccountNotInLdap.new(I18n.t("alert.account_not_in_ldap")) if profile.blank?
    raise Rigi::AccountNoCasino.new(I18n.t("alert.account_no_casino")) if profile[:casino_ids].blank?
    profile
  end

  def ldap_login!(auth_source_detail, username, password)
    result = false
    Rails.logger.info "[auth_source_id=#{self.id}]LDAP authenticating to #{username}...."
    result = initialize_ldap_con(auth_source_detail, username, password).bind if username.present? && password.present?
    unless result
      Rails.logger.error "SystemUser[username=#{username}] Login failed. Authentication failed"
      raise Rigi::InvalidLogin.new("alert.invalid_login")
    end
  end

  def memberof_has_key?(pair, regexp, key)
    dn_attributes = pair.scan(regexp)
    unless dn_attributes.empty?
      dn_attributes.each do |dn_attribute|
        digit = dn_attribute.scan(/\d+/).first
        return true if digit && digit == key.to_s
      end
    end
    false
  end

  def initialize_ldap_con(auth_source_detail, ldap_user, ldap_password)
    options = { :host => auth_source_detail['data']['host'],
                :port => auth_source_detail['data']['port'] || 3268,
                :encryption => nil,
                :auth => {
                  :method => :simple,
                  :username => ldap_user || auth_source_detail['data']['account'],
                  :password => ldap_password || auth_source_detail['data']['password']
                }
              }
    Net::LDAP.new options
  end
end
