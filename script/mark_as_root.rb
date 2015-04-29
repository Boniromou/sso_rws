require 'sequel'
require 'yaml'

if ARGV.length != 2
        puts "Usage: ruby script/mark_as_root.rb <env> <username>"
        puts "Example: ruby script/mark_as_root.rb staging0 lucy.cheung"
    Process.exit
end

env = ARGV[0]
username = ARGV[1]

mysql_configs = YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/../config/database.yml')

mysqldb = mysql_configs[env]

@db = Sequel.connect(sprintf('%s://%s:%s@%s:%s/%s',
                           mysqldb['adapter'],
                           mysqldb['username'],
                           mysqldb['password'],
                           mysqldb['host'],
                           mysqldb['port'] || 3306,
                           mysqldb['database']), :encoding => mysqldb['encoding'])

system_user = @db[:system_users].where(:username => username).first

unless system_user
  p "System User #{username} not found!"
  Process.exit
end

@db[:system_users].where(:username => username).update(:admin => true)

p "System User #{username} marked as root successfully!"
