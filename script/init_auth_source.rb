require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/init_auth_source.rb <env> <file_name>"
  puts "Example: ruby script/init_auth_source.rb development config/ldap.yml"
  Process.exit
end

Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
env = ARGV[0]
file_name = ARGV[1]

auth_source = YAML.load_file(file_name)[env]
sso_db = Database.connect(env)

p auth_source
domain_name = auth_source['domain_name']
auth_source_info = {:name => auth_source['name'],
                    :host => auth_source['host'],
                    :port => auth_source['port'],
                    :account => auth_source['account'],
                    :password => auth_source['password'],
                    :base_dn => auth_source['base_dn'],
                    :encryption => auth_source['encryption'],
                    :method => auth_source['method'],
                    :search_scope => auth_source['search_scope'],
                    :admin_account => auth_source['admin_account'],
                    :admin_password => auth_source['admin_password'],
                    :auth_type => "AuthSourceLdap"}

auth_sources_table = sso_db[:auth_sources]
domain_table = sso_db[:domains]

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp
if prompt.casecmp('Y') == 0
  auth_source = auth_sources_table.where(:name => auth_source_info[:name]).first
  sso_db.transaction do
    if auth_source
      auth_source_id = auth_source[:id]
      auth_sources_table.where(:name => auth_source_info[:name]).update(auth_source_info)
    else
      auth_source_id = auth_sources_table.insert(auth_source_info)
    end

    if domain_table.where(name: domain_name).count == 0
      raise "update domain-ldap mapping error: domain[#{domain_name}] not exist."
    else
      domain_table.where(name: domain_name).update(:auth_source_id => auth_source_id, :updated_at => Time.now.utc)
    end
  end
end