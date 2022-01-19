require 'roo'
require 'yaml'
require 'sequel'
require 'logger'
require 'ulid'

env = ARGV[0]
file_name = ARGV[1]
sheet_name = 'AAOS'

if !env || !file_name
        puts "Usage: ruby script/role_scripts/load_agent_permission.rb <env> <file_name>"
        puts "Example: ruby script/role_scripts/load_agent_permission.rb development role_permission_files/AdminPortal_Configuration_v0.31.xlsx"
    Process.exit
end

datas = {
  'development' => {host: 'hq-int-generic-db02.laxino.local', port: 3306, database: 'esabong_aaos_development', username: 'esabong', password: 'esabong'},
  'staging1' => {host: 'aaos-vdb01.stg1.ias.local', port: 3306, database: 'esabong_aaos_staging', username: 'esabong', password: 'esabong'}
}


permission_columns = { :action => 'action', :target => 'target' }
permission_indicator = 'Y'

role_permission_data = {}
permission_data = []
s = Roo::Excelx.new(file_name)
s.default_sheet = sheet_name

role_first_col_index = permission_columns.length + 1
role_last_col_index = s.last_column
role_columns = {}

(role_first_col_index..role_last_col_index).to_a.each do |col_index|
  role = s.column(col_index)[0]
  role_columns[role] = role
end

role_columns.delete_if { |key, value| value == '' }

p '---------------------------------------------------'
p 'found roles'
p role_columns
p '---------------------------------------------------'

cols = permission_columns.merge(role_columns)

s.each(cols) do |row|
  # skip header row
  next if row[:action] == 'action'
  next if row[:action] == '' && row[:target] == ''

  permission_data << { :action => row[:action], :target => row[:target]}

  role_columns.each_key do |role|
    role_permission_data[role] ||= {}
    if row[role] && row[role].split(':')[0] && row[role].split(':')[0].upcase == permission_indicator
      role_permission_data[role][:grant] ||= []
      role_permission_data[role][:grant] << { :action => row[:action], :target => row[:target]}
    else
      role_permission_data[role][:revoke] ||= []
      role_permission_data[role][:revoke] << { :action => row[:action], :target => row[:target]}
    end
  end
end


print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp

Process.exit if prompt.upcase != 'Y'

data = datas[env]
DB = Sequel.connect(sprintf('%s://%s:%s@%s:%s/%s', 'mysql2', data[:username], data[:password], data[:host], data[:port], data[:database]), :encoding => 'utf8', :loggers => Logger.new($stdout))

DB.transaction do
  # insert permission
  permission_data.each do |permission_h|
    permission = DB[:permissions].where(action: permission_h[:action], target: permission_h[:target]).first

    if permission.nil?
      DB[:permissions].insert(:id => ULID.generate, :action => permission_h[:action], :target => permission_h[:target], :created_at => Time.now.utc, :updated_at => Time.now.utc)
    end
  end

  role_permission_data.each do |rank, permissions|
    if permissions[:grant]
      permissions[:grant].each do |permission_h|
        permission = DB[:permissions].where(action: permission_h[:action], target: permission_h[:target]).first
        role_permission = DB[:ranks_permissions].where(rank: rank, permission_id: permission[:id]).first

        if role_permission.nil?
          DB[:ranks_permissions].insert(:id => ULID.generate, :rank => rank, :permission_id => permission[:id], :created_at => Time.now.utc, :updated_at => Time.now.utc)
        end
      end
    end

    if permissions[:revoke]
      permissions[:revoke].each do |permission_h|
        permission = DB[:permissions].where(action: permission_h[:action], target: permission_h[:target]).first
        role_permission = DB[:ranks_permissions].where(rank: rank, permission_id: permission[:id]).first

        if role_permission
          DB[:ranks_permissions].where(rank: rank, permission_id: permission[:id]).delete
        end
      end
    end
  end
end
