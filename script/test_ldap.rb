require 'net/ldap'
require 'net/ldap/dn'

username = ARGV[0] || 'gs.admin@scdnuat.com'

auth_source_detail = {
  "host" =>"10.255.2.11",
  "port" =>389,
  "account" =>"svc_ldap@scdnuat.com",
  "password" =>"H#%g;7@@~XZJ9b-~",
  "admin_account" =>"svc_ldap@scdnuat.com",
  "admin_password" =>"H#%g;7@@~XZJ9b-~",
#  "base_dn" =>"OU=GameSourceCloud,OU=External Support,DC=scdnuat,DC=com"
  "base_dn" =>"OU=Game Source,OU=SUNCITY-TRAINING,DC=SCDNUAT,DC=com"
}

options = { :host => auth_source_detail['host'],
            :port => auth_source_detail['port'] || 3268,
            :encryption => nil,
            :auth => {
              :method => :simple,
              :username => auth_source_detail['account'],
              :password => auth_source_detail['password']
            }
          }
ldap = Net::LDAP.new options
p auth_source_detail['account'] + ' login result:'
p ldap.bind
p ldap.get_operation_result


search_filter = Net::LDAP::Filter.eq("userPrincipalName", username)
ldap_entry = ldap.search(:base => auth_source_detail['base_dn'], :filter => search_filter, :return_result => true, :scope => Net::LDAP::SearchScope_WholeSubtree).first

p "search #{username} result"
p ldap_entry
