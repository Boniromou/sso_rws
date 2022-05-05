require 'roo'
require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 3
        puts "Usage: ruby script/role_scripts/load_role_permission.rb <env> <file_name> <sheet_name>"
        puts "Example: ruby script/role_scripts/load_role_permission.rb development role_permission_files/AdminPortal_Configuration_v0.31.xlsx AP"
    Process.exit
end

env = ARGV[0]
file_name = ARGV[1]
sheet_name = ARGV[2]

apps_info = {
              :SSO => {:name => 'user_management' },
              :AP => {:name => 'gaming_operation' },
              :CAGE => {:name => 'cage' },
              :SM => {:name => 'station_management' },
              :GRMS => {:name => 'game_recall' },
              :SV => {:name => 'signature_verifier' },
              :AUDP => {:name => 'audit_portal' },
              :DAM => {:name => 'asset_management'},
              :TPMS => {:name => 'trade_promotion'},
              :MDS => {:name => 'master_data_service'},
              :SSRS => {:name => 'report_portal'},
              :MP => {:name => 'marketing_portal'},
              :OGR => {:name => 'platform_game_recall'},
              :GOP => {:name => 'platform_gaming_operation'},
              :KOS => {:name => 'kiosk_management'},
              :TOP => {:name => 'tournament_portal'},
              :SVP => {:name => 'signature_verifier_portal'},
              :SPP => {:name => 'signature_management'},
              :LMP => {:name => 'spindle'},
              :POP => {:name => 'player_operations_portal'},
              :PGDP => {:name => 'portable_gaming_device_portal'},
              :IAUDP => {:name => 'inspection_and_audit_portal'},
              :PAOP => {:name => 'player_approval_operations_portal'},
              :GFP => {:name => 'game_feeds_portal'},
              :SUPD => {:name => 'supervisor_dashboard'}

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

Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
sso_db = Database.connect(ARGV[0])

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp

if prompt == 'Y'
  apps_table = sso_db[:apps]
  role_types_table = sso_db[:role_types]
  roles_table = sso_db[:roles]
  permissions_table = sso_db[:permissions]
  role_permissions_table = sso_db[:role_permissions]
  app_name = apps_info[sheet_name.to_sym][:name]

  sso_db.transaction do
    app = apps_table.where(:name => app_name).first
    if app.nil?
      apps_table.insert(:name => app_name, :created_at => Time.now.utc, :updated_at => Time.now.utc)
    end

    app_id = apps_table.where(:name => app_name).first[:id]

    role_type_info.each do |role_type_id, role_type_name|
      role_type = role_types_table.where(id: role_type_id, name: role_type_name).first

      if role_type.nil?
        role_types_table.insert(:id => role_type_id, :name => role_type_name, :created_at => Time.now.utc, :updated_at => Time.now.utc)
      end
    end

    # TODO: truncate role_permissions_table and permissions_table before insert
    permission_data.each do |permission_h|
      permission = permissions_table.where(name: permission_h[:action], target: permission_h[:target], app_id: app_id).first

      if permission.nil?
        permissions_table.insert(:name => permission_h[:action], :action => permission_h[:action], :target => permission_h[:target], :app_id => app_id, :created_at => Time.now.utc, :updated_at => Time.now.utc)
      end
    end

    role_permission_data.each do |role_name, permissions|
      role = roles_table.where(name: role_name, app_id: app_id).first

      if role.nil?
        role = {}
        role[:id] = roles_table.insert(:name => role_name, :app_id => app_id, :role_type_id => role_types_data[role_name.to_s], :created_at => Time.now.utc, :updated_at => Time.now.utc)
      else
        roles_table.where(id: role[:id]).update(:role_type_id => role_types_data[role_name.to_s], :updated_at => Time.now.utc)
      end

      if permissions[:grant]
        permissions[:grant].each do |permission_h|
          permission = permissions_table.where(name: permission_h[:action], target: permission_h[:target], app_id: app_id).first
          role_permission_obj = role_permissions_table.where(role_id: role[:id], permission_id: permission[:id])
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
          permission = permissions_table.where(name: permission_h[:action], target: permission_h[:target], app_id: app_id).first
          role_permission = role_permissions_table.where(role_id: role[:id], permission_id: permission[:id]).first

          if role_permission
            role_permissions_table.where(role_id: role[:id], permission_id: permission[:id]).delete
          end
        end
      end
    end
  end
end
