require 'roo'
require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 3
        puts "Usage: ruby script/load_role_permission.rb <env> <file_name> <sheet_name>"
        puts "Example: ruby script/load_role_permission.rb development role_permission_files/AdminPortal_Configuration_v0.31.xlsx AP"
    Process.exit
end

env = ARGV[0]
file_name = ARGV[1]
sheet_name = ARGV[2]

apps_info = { 
              :SSO => { :id => 1, :name => 'user_management' }, 
              :AP => { :id => 2, :name => 'gaming_operation' }, 
              :CAGE => { :id => 3, :name => 'cage' }, 
              :SM => { :id => 4, :name => 'station_management' },
              :GRMS => { :id => 5, :name => 'game_recall' },
              :SV => { :id => 6, :name => 'signature_verifier' },
              :AUDP => { :id => 7, :name => 'audit_portal' },
              :DAM => {:id => 8, :name => 'asset_management'},
              :TPMS => {:id => 9, :name => 'trade_promotion'},
              :MDS => {:id => 10, :name => 'master_data_service'},
              :SSRS => {:id => 11, :name => 'report_protal'}
            }
role_type_info = { '1' => 'internal', '2' => 'external' }
permission_columns = { :action => 'action', :target => 'target' }
permission_indicator = 'Y'

role_permission_data = {}
permission_data = []
s = Roo::Excelx.new(file_name)
s.default_sheet = sheet_name

role_first_col_index = permission_columns.length + 1
role_last_col_index = s.last_column
role_columns = {}
role_types_data = {}

(role_first_col_index..role_last_col_index).to_a.each do |col_index|
  type_id = s.column(col_index)[0]
  role = s.column(col_index)[1]
  role_columns[role] = role
  role_types_data[role] = type_id
end

role_columns.delete_if { |key, value| value == '' }
role_types_data.delete_if { |key, value| value == '' }

p '---------------------------------------------------'
p 'found roles'
#p role_columns.values
p role_types_data
p '---------------------------------------------------'

cols = permission_columns.merge(role_columns)

s.each(cols) do |row|
# row = {:action=>"list_rejected", :target=>"release_candidate", :change_coordinator=>"Y", :service_desk_manager=>"Y", :service_desk_agent=>nil, :product_manager=>"Y", :it_support=>"Y"}

  # skip header row
  next if row[:action] == 'internal_external_role'
  next if row[:action] == 'action'
  next if row[:action] == '' && row[:target] == ''

  permission_data << { :action => row[:action], :target => row[:target]}

  role_columns.each_key do |role|
    role_permission_data[role] ||= {}
    if row[role] && row[role].split(':')[0] && row[role].split(':')[0].upcase == permission_indicator
      role_permission_data[role][:grant] ||= []
      role_permission_data[role][:grant] << { :action => row[:action], :target => row[:target], :value => row[role].split(':',2)[1]}
    else
      role_permission_data[role][:revoke] ||= []
      role_permission_data[role][:revoke] << { :action => row[:action], :target => row[:target]}
    end
  end
end


p 'found permissions'
p permission_data
p '---------------------------------------------------'

=begin
p '---------------------------------------------------'
p 'role_permission_data'
p role_permission_data
p '---------------------------------------------------'
=end

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

if prompt == 'Y'
  apps_table = sso_db[:apps]
  role_types_table = sso_db[:role_types]
  roles_table = sso_db[:roles]
  permissions_table = sso_db[:permissions]
  role_permissions_table = sso_db[:role_permissions]
  app_id = apps_info[sheet_name.to_sym][:id]
  app_name = apps_info[sheet_name.to_sym][:name]

  sso_db.transaction do
    app = apps_table.where("id = ? and name = ?", app_id, app_name).first

    if app.nil?
      apps_table.insert(:id => app_id, :name => app_name, :created_at => Time.now.utc, :updated_at => Time.now.utc)
    end

    role_type_info.each do |role_type_id, role_type_name|
      role_type = role_types_table.where("id = ? and name = ?", role_type_id, role_type_name).first

      if role_type.nil?
        role_types_table.insert(:id => role_type_id, :name => role_type_name, :created_at => Time.now.utc, :updated_at => Time.now.utc)
      end
    end

    # TODO: truncate role_permissions_table and permissions_table before insert
    permission_data.each do |permission_h|
      permission = permissions_table.where("name = ? and target = ? and app_id = ?", permission_h[:action], permission_h[:target], app_id).first

      if permission.nil?
        permissions_table.insert(:name => permission_h[:action], :action => permission_h[:action], :target => permission_h[:target], :app_id => app_id, :created_at => Time.now.utc, :updated_at => Time.now.utc)
      end
    end

    role_permission_data.each do |role_name, permissions|
      role = roles_table.where("name = ? and app_id = ?", role_name, app_id).first

      if role.nil?
        role = {}
        role[:id] = roles_table.insert(:name => role_name, :app_id => app_id, :role_type_id => role_types_data[role_name.to_s], :created_at => Time.now.utc, :updated_at => Time.now.utc)
      else
        roles_table.where("id = ?", role[:id]).update(:role_type_id => role_types_data[role_name.to_s], :updated_at => Time.now.utc)
      end

      if permissions[:grant]
        permissions[:grant].each do |permission_h|
          permission = permissions_table.where("name = ? and target = ? and app_id = ?", permission_h[:action], permission_h[:target], app_id).first
          role_permission_obj = role_permissions_table.where("role_id = ? and permission_id = ?", role[:id], permission[:id])
          role_permission = role_permission_obj.first

          if role_permission.nil?
            role_permissions_table.insert(:role_id => role[:id], :permission_id => permission[:id], :value => permission_h[:value], :created_at => Time.now.utc, :updated_at => Time.now.utc)
          else
            role_permission_obj.update(:value => permission_h[:value])
          end
        end
      end

      if permissions[:revoke]
        permissions[:revoke].each do |permission_h|
          permission = permissions_table.where("name = ? and target = ? and app_id = ?", permission_h[:action], permission_h[:target], app_id).first
          role_permission = role_permissions_table.where("role_id = ? and permission_id = ?", role[:id], permission[:id]).first

          if role_permission
            role_permissions_table.where("role_id = ? and permission_id = ?", role[:id], permission[:id]).delete
          end
        end
      end
    end
  end
end
