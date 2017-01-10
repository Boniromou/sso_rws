require 'sequel'
require 'logger'
require 'yaml'

if ARGV.length != 3
  puts "Usage: ruby script/remove_role.rb <env> <app_name> <role_name>"
  puts "Example: ruby script/remove_role.rb development user_management tester"
  Process.exit
end

env = ARGV[0]
app_name = ARGV[1]
role_name = ARGV[2]

print "Remove role[#{app_name}-#{role_name}]? (Y/n): "
prompt = STDIN.gets.chomp
if prompt.casecmp('Y') == 0
	Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
	sso_db = Database.connect(env)
	role_table = sso_db[:roles]
	app_talbe = sso_db[:apps]
	role_permission_table = sso_db[:role_permissions]
	role_assignment_table = sso_db[:role_assignments]

	app = app_talbe.where(name: app_name).first
	role = role_table.where(name: role_name, app_id: app[:id]).first
	if role.nil?
		puts "remove role[#{role_name}] failed: role not exist"
		Process.exit
	end
	if role_assignment_table.where(role_id: role[:id]).count > 0
		puts "remove role[#{role_name}] failed: someone assign role"
	else
		sso_db.transaction do
	    role_permission_table.where(role_id: role[:id]).delete
	    role_table.where(id: role[:id]).delete
			puts "remove role[#{role_name}] successfully"
	  end
	end
end
