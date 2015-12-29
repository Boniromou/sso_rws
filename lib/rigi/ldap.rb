module Rigi
  module Ldap
    extend self

    DISABLED_ACCOUNT_TOKEN = 'Disabled Accounts'
    MATCH_PATTERN_REGEXP = /CN=\d+iportal/

    def search(username)
      ldap_config = Rails.application.config.ldap_config

      ldap = Net::LDAP.new :host => ldap_config[:host],
          :port => ldap_config[:port] || 389,
          :auth => {
                :method => ldap_config[:method],
                :username => ldap_config[:binddn],
                :password => ldap_config[:password]
          }

      search_filter = Net::LDAP::Filter.eq("sAMAccountName", username)

      
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
      ldap.search( :base => ldap_config[:searchbase], :filter => search_filter, :return_result => true )
    end

    #
    # retrieve_user_profile('ray.chan', [1003, 1007, 1014, 1021, 20000, 30000])
    #
    # # if ray.chan is an AD account as a member of 1003, 1007
    # => {:account_status => true, :groups => [1003, 1007]}
    #
    def retrieve_user_profile(username, filter_groups=[])
      ldap_entry = search(username).first
      dnames = ldap_entry[:distinguishedName]
      memberofs = ldap_entry[:memberOf]
      is_disable_account, is_admin_group = false, false
      groups = []

      Rails.logger.info "Ldap server response: distinguishedName => #{dnames}, memberOf => #{memberofs}"

      is_disable_account = dnames.any? { |dn| dn.include?(DISABLED_ACCOUNT_TOKEN) }
      is_admin_group = dnames.any? { |dn| dn_has_admin_group?(dn) }

      if is_admin_group
        groups << ADMIN_PROPERTY_ID
      else
        memberofs.each do |memberof|
          filter_groups.each do |filter|
            groups << filter.to_i if memberof_has_key?(memberof, MATCH_PATTERN_REGEXP, filter.to_s)
          end
        end
      end

      res = { :account_status => !is_disable_account, :groups => groups.uniq }
      Rails.logger.info "[username=#{username}][filter_groups=#{filter_groups}] account result => #{res.inspect}"

      res
    end

    def dn_has_admin_group?(raw_dn)
      if raw_dn.include?("OU=Users")
        true
      elsif raw_dn.include?("OU=Licensee")
        false
      else
        false
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
  end
end