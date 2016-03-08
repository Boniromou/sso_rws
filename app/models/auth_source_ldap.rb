require 'net/ldap'
require 'net/ldap/dn'
require 'timeout'

class AuthSourceLdap < AuthSource
  DISABLED_ACCOUNT_KEY = 'Disabled Accounts'
  MATCH_PATTERN_REGEXP = /CN=\d+casinoid/

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
    options = { :host => self.host,
                :port => self.port || 389,
                :encryption => nil,
                :auth => {
                  :method => :simple,
                  :username => ldap_user,
                  :password => ldap_password
                  }
                }
    Net::LDAP.new options
  end

  def search(username, domain)
    options = { :host => self.host,
                :port => self.port || 3268,
                :auth => {
                  :method => self.method || :simple,
                  :username => self.account,
                  :password => self.account_password
                }
              }

    ldap = Net::LDAP.new(options)

    search_filter = Net::LDAP::Filter.eq("userPrincipalName", "#{username}@#{domain}")

=begin ... do |entry|
      Rails.logger.debug "DN: #{entry.dn}"

      entry.each do |attribute, values|
        Rails.logger.debug "   #{attribute}:"

        values.each do |value|
          Rails.logger.debug "      --->#{value}"
        end
      end
    end
=end

    ldap.search( :base => self.base_dn, :filter => search_filter, :return_result => true, :scope => self.search_scope || Net::LDAP::SearchScope_WholeSubtree)
  end

=begin
  def get_domain
    dn_arr = self.base_dn.split(',')
    dn_arr.first.split('=')[1]
  end
=end

  #
  # retrieve_user_profile('ray.chan', [1003, 1007, 1014, 1021, 20000, 30000])
  #
  # # if ray.chan is an AD account as a member of 1003, 1007
  # => {:account_status => true, :groups => [1003, 1007]}
  #
  def retrieve_user_profile(username, domain, filter_groups=[])
    ldap_entry = search(username, domain).first
    dnames = ldap_entry[:distinguishedName]
    memberofs = ldap_entry[:memberOf]
    is_disable_account, is_admin_group = false, false
    groups = []

    Rails.logger.info "Ldap server response: distinguishedName => #{dnames}, memberOf => #{memberofs}"

    is_disable_account = dnames.any? { |dn| dn.include?(DISABLED_ACCOUNT_KEY) }
#    is_admin_group = dnames.any? { |dn| dn_has_admin_group?(dn) }

#    if is_admin_group
#      groups << ADMIN_CASINO_ID
#    else
      memberofs.each do |memberof|
        filter_groups.each do |filter|
          groups << filter.to_i if memberof_has_key?(memberof, MATCH_PATTERN_REGEXP, filter.to_s)
        end
      end
#    end

    res = { :status => !is_disable_account, :casino_ids => groups.uniq }
    Rails.logger.info "[username=#{username}][filter_groups=#{filter_groups}] account result => #{res.inspect}"

    res
  end

=begin
  def dn_has_admin_group?(raw_dn)
    if raw_dn.include?("OU=Users")
      true
    elsif raw_dn.include?("OU=Licensee")
      false
    else
      false
    end
  end
=end

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
end
