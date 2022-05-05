require 'net/ldap'
require 'net/ldap/dn'
require 'yaml'
require 'json'
require 'fileutils'
require 'sequel'
require 'logger'

env = ARGV[0]
username = ARGV[1]
auth_source_name = ARGV[2] || 'laxino_openldap'

if !env
  puts "Usage: ruby script/test_scripts/test_ldap.rb <env> <username> <auth_source_name>"
  puts "Example: ruby script/test_scripts/test_ldap.rb development ldapuser01@openldap.local laxino_openldap"
  Process.exit
end

Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])

auth_source_detail = db[:auth_source_details].where(name: auth_source_name).first[:data]
auth_source_detail = JSON.parse(auth_source_detail)
base_dn = auth_source_detail['base_dn']

# test login------------------------------
user, domain = auth_source_detail['account'].split('@')
account = "cn=#{user},#{domain.split('.').map{|d| "dc=#{d}"}.join(',')}"
options = { :host => auth_source_detail['host'],
            :port => auth_source_detail['port'] || 3268,
            :encryption => nil,
            :auth => {
              :method => :simple,
              :username => account,
              :password => auth_source_detail['password']
            }
          }
ldap = Net::LDAP.new options
p account + ' login result:'
p ldap.bind
p ldap.get_operation_result
# end test login------------------------------


Process.exit unless username
user, domain = username.split('@')


# test search user------------------------------
search_filter = Net::LDAP::Filter.eq('cn', user)
ldap_entry = ldap.search(:base => base_dn, :filter => search_filter, :return_result => true, :scope => Net::LDAP::SearchScope_WholeSubtree)
p "search user [#{user}] result:"
p ldap_entry
# end test search user------------------------------


# test search user group------------------------------
username = "cn=#{user},ou=User,#{domain.split('.').map{|d| "dc=#{d}"}.join(',')}"
# search_filter = Net::LDAP::Filter.eq("memberUid", 'cn=PortalAdmins02,ou=Group,dc=openldap,dc=local')
search_filter = Net::LDAP::Filter.eq('memberUid', username)
ldap_entry = ldap.search(:base => base_dn, :filter => search_filter, :return_result => true, :scope => Net::LDAP::SearchScope_WholeSubtree)
p "search user [#{username}] group result:"
p ldap_entry
memberofs = []
ldap_entry.each {|entry| memberofs += entry[:cn] }
p "casino groups #{memberofs}"
# end test search user group------------------------------

