require 'roo'
require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 1
        puts "Usage: ruby script/map_role_assignment.rb <env>"
        puts "Example: ruby script/map_role_assignment.rb development"
    Process.exit
end

env = ARGV[0]

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

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp

migrated_role_info = 
[
  {
    id: 1,
    name: "user_manager",
    app_id: 1
  },
  {
    id: 3,
    name: "change_coordinator",
    app_id: 2
  },
  {
    id: 4,
    name: "service_desk_manager",
    app_id: 2
  },
  {
    id: 5,
    name: "service_desk_agent",
    app_id: 2
  },
  {
    id: 6,
    name: "product_manager",
    app_id: 2
  },
  {
    id: 12,
    name: "it_support",
    app_id: 1
  },
  {
    id: 13,
    name: "it_support",
    app_id: 2
  }
]

if prompt == 'Y'
  role_assignment_table = sso_db[:role_assignments]
  roles_table = sso_db[:roles]

  sso_db.transaction do
    migrated_role_info.each do |migrated_role|
      current_role = roles_table.where("name = ? and app_id = ?", migrated_role[:name], migrated_role[:app_id]).first

      if current_role
        role_assignment_table.where("role_id = ?", migrated_role[:id]).update(:role_id => current_role[:id],:updated_at => Time.now.utc)
      else
        role_assignment_table.where("role_id = ?", migrated_role[:id]).delete
      end
    end
  end
end