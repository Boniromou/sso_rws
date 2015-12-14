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
      account_status = true
      groups = []

      dnames.each do |dn|
        account_status = false if dn.include?(DISABLED_ACCOUNT_TOKEN)
      end

      memberofs.each do |memberof|
        filter_groups.each do |filter|
          groups << filter.to_i if dn_has_key?(memberof, filter.to_s)
        end
      end

      res = { :account_status => account_status, :groups => groups.uniq }
      Rails.logger.info "[username=#{username}][filter_groups=#{filter_groups}] AD return result => res.inspect"

      res
    end

    # "CN=20000iportal,OU=20000_30000,OU=Licensee,OU=Laxino Macau,DC=mo,DC=laxino,DC=com"
    def dn_has_key?(raw_dn, key)
      dn_attributes = raw_dn.scan(MATCH_PATTERN_REGEXP)

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