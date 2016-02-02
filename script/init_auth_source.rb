require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/init_auth_source.rb <env> <file_name>"
  puts "Example: ruby script/init_auth_source.rb development config/ldap.yml"
  Process.exit
end

env = ARGV[0]
file_name = ARGV[1]

auth_source = YAML.load_file(file_name)[env]
mysql_configs = YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/../config/database.yml')
mysqldb = mysql_configs[env]
sso_db = Sequel.connect(sprintf('%s://%s:%s@%s:%s/%s',
                           mysqldb['adapter'],
                           mysqldb['username'],
                           mysqldb['password'],
                           mysqldb['host'],
                           mysqldb['port'] || 3306,
                           mysqldb['database']), :encoding => mysqldb['encoding'],
                          :loggers => Logger.new($stdout))

p auth_source
auth_source_info = {:name => auth_source['name'], 
                    :host => auth_source['host'],
                    :port => auth_source['port'],
                    :account => auth_source['account'],
                    :account_password => auth_source['password'],
                    :base_dn => auth_source['base_dn'],
                    :encryption => auth_source['encryption'],
                    :method => auth_source['method'],
                    :search_scope => auth_source['search_scope'],
                    :auth_type => "AuthSourceLdap"}

auth_sources_table = sso_db[:auth_sources]
existed = auth_sources_table.first

if existed
  auth_sources_table.where(:id => existed[:id]).update(auth_source_info)
else
  auth_sources_table.insert(auth_source_info)
end