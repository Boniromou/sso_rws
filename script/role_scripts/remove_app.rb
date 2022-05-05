require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/role_scripts/remove_app.rb <env> <app_name>"
  puts "Example: ruby script/role_scripts/remove_app.rb development game_recall"
  Process.exit
end

Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
env = ARGV[0]
app_name = ARGV[1]
db = Database.connect(env)

app = db[:apps].where(name: app_name).first
role_ids = db[:roles].where(app_id: app[:id]).map{|role| role[:id]}
permission_ids = db[:permissions].where(app_id: app[:id]).map{|p| p[:id]}


print "Remove app[#{app_name}]? (Y/n): "
prompt = STDIN.gets.chomp
return unless prompt.casecmp('Y') == 0

db.transaction do
  db[:role_permissions].where(role_id: role_ids).delete
  db[:role_permissions].where(permission_id: permission_ids).delete
  db[:role_assignments].where(role_id: role_ids).delete
  db[:roles].where(app_id: app[:id]).delete
  db[:permissions].where(app_id: app[:id]).delete
  db[:app_system_users].where(app_id: app[:id]).delete
  db[:apps].where(id: app[:id]).delete
  puts "remove app[#{app_name}] successfully"
end
