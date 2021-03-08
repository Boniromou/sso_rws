require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/remove_domain.rb <env> <domain_name>"
  puts "Example: ruby script/remove_domain.rb development mo.laxino.com,dctest.local"
  Process.exit
end

Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
env = ARGV[0]
domain_data = ARGV[1]
domain_names = domain_data.split(',')

sso_db = Database.connect(env)
domain_table = sso_db[:domains]
auth_source_table = sso_db[:auth_sources]

print "Remove domain[#{domain_data}]? (Y/n): "
prompt = STDIN.gets.chomp
if prompt.casecmp('Y') == 0
  domain_names.each do |domain_name|
    domain = domain_table.where(name: domain_name).first
    if domain
      sso_db.transaction do
        domain_table.where(name: domain_name).delete
        auth_source_table.where(id: domain[:auth_source_id]).delete if domain[:auth_source_id]
        puts "remove domain[#{domain_name}] and auth_source successfully"
      end
    else
      puts "domain[#{domain_name}] not found"
    end
  end
end
