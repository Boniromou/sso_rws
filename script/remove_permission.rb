require 'sequel'
require 'logger'
require 'yaml'

if ARGV.length != 3 && ARGV.length != 4
  puts "Usage: ruby script/remove_permission.rb <env> <app_name> <target> <permission>"
  puts "Example: ruby script/remove_permission.rb development user_management system_user show"
  Process.exit
end

env = ARGV[0]
app_name = ARGV[1]
target = ARGV[2]
action = ARGV[3]

print "Remove permission[#{app_name}-#{target}-#{action}]? (Y/n): "
prompt = STDIN.gets.chomp
if prompt.casecmp('Y') == 0
	Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
	sso_db = Database.connect(env)
	permission_table = sso_db[:permissions]
	app_talbe = sso_db[:apps]
	role_permission_table = sso_db[:role_permissions]

	app = app_talbe.where(name: app_name).first
	if action.nil?
		permissions = permission_table.where(target: target, app_id: app[:id])
	else
		permissions = permission_table.where(target: target, action: action, app_id: app[:id])
	end
	
	permission_ids = permissions.map{|permission| permission[:id]}
	if permission_ids.size > 0
		sso_db.transaction do
	    role_permission_table.where(permission_id: permission_ids).delete
	  	permission_table.where(id: permission_ids).delete
			puts "remove permission[#{app_name}-#{target}-#{action}] successfully"
		end
	end
end
