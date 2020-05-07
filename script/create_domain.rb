require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'
Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }

if ARGV.length != 2
  puts "Usage: ruby script/create_domain.rb <env> <domain_name>"
  puts "Example: ruby script/create_domain.rb development mo.laxino.com"
  Process.exit
end

env = ARGV[0]
domain_name = ARGV[1]

sso_db = Database.connect(env)

print "Create domain[#{domain_name}]? (Y/n): "
prompt = STDIN.gets.chomp
exit unless prompt.casecmp('Y') == 0

if sso_db[:domains].where({name: domain_name}).count == 0
  domain_table.insert({name: domain_name, created_at: Time.now.utc, updated_at: Time.now.utc}))
end
