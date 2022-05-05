require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

env = ARGV[0]
domain_name = ARGV[1]
user_type = ARGV[2] || 'Ldap'

if !env || !domain_name
  puts "Usage: ruby script/init_scripts/create_domain.rb <env> <domain_name> <user_type>"
  puts "Example: ruby script/init_scripts/create_domain.rb development mo.laxino.com Ldap"
  Process.exit
end

Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])

print "Create domain[#{domain_name}]? (Y/n): "
prompt = STDIN.gets.chomp
exit unless prompt.casecmp('Y') == 0

if db[:domains].where({name: domain_name}).count == 0
  db[:domains].insert({name: domain_name, user_type: user_type, created_at: Time.now.utc, updated_at: Time.now.utc})
end
