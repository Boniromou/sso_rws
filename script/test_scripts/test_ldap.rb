require 'net/ldap'
require 'net/ldap/dn'
require 'yaml'
require 'json'
require 'fileutils'
require 'sequel'
require 'logger'

env = ARGV[0]
username = ARGV[1]
auth_source_name = ARGV[2] || 'laxino_ldap'

if !env
  puts "Usage: ruby script/test_scripts/test_ldap.rb <env> <username> <auth_source_name>"
  puts "Example: ruby script/test_scripts/test_ldap.rb development gs.admin@scdnuat.com laxino_ldap"
  Process.exit
end

Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])

auth_source_detail = db[:auth_source_details].where(name: auth_source_name).first[:data]
auth_source_detail = JSON.parse(auth_source_detail)
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


Process.exit unless username
search_filter = Net::LDAP::Filter.eq("userPrincipalName", username)
ldap_entry = ldap.search(:base => auth_source_detail['base_dn'], :filter => search_filter, :return_result => true, :scope => Net::LDAP::SearchScope_WholeSubtree).first

p "search #{username} result"
p ldap_entry
