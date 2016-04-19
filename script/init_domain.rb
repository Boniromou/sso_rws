require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/init_domain.rb <env> <file_name>"
  puts "Example: ruby script/init_domain.rb development config/domain.yml"
  Process.exit
end

env = ARGV[0]
file_name = ARGV[1]
config_data = YAML.load_file(file_name)[env]

domains         = config_data['domains']
domains_casinos = config_data['domains_casinos']

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

if domains
  domain_info = []
  domains.each do |domain|
    domain_info.push({:id => domain['id'],:name => domain['name']})
  end
end

if domains_casinos
  domains_casino_info = []
  domains_casinos.each do |domains_casino|
    domains_casino_info.push({:id => domains_casino['id'], :casino_id => domains_casino['casino_id'], :domain_id => domains_casino['domain_id']})
  end
end

domain_table         = sso_db[:domains]
domains_casino_table = sso_db[:domains_casinos]
system_user_table    = sso_db[:system_users]

domain_info.each do |domain|
  domain_table.insert(domain.merge(:created_at => Time.now.utc, :updated_at => Time.now.utc)) if domain_table.where(domain).count == 0
  #system_user_table.where(:domain => domain[:name]).update(:domain_id => domain[:id])
  system_user_table.update(:domain_id => domain[:id])
end

domains_casino_info.each do |domains_casino|
  domains_casino_table.insert(domains_casino.merge(:created_at => Time.now.utc, :updated_at => Time.now.utc))  if domains_casino_table.where(domains_casino).count == 0
end





