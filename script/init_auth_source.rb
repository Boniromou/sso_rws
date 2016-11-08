require 'roo'
require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'
Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }

if ARGV.length != 3
  puts "Usage: ruby script/init_auth_source.rb <env> <file_name> <sheet_name>"
  puts "Example: ruby script/init_auth_source.rb development ldap_config_files/ldap_config.xlsx Sheet1"
  Process.exit
end

env = ARGV[0]
file_name = ARGV[1]
sheet_name = ARGV[2]

def format_text(str)
  str.is_a?(String) ? str.strip : str 
end

sso_db = Database.connect(env)
auth_sources_table = sso_db[:auth_sources]
licensee_table = sso_db[:licensees]
columns = {:licensee_id => 'licensee_id', :name => 'name', :host => 'host', :port => 'port', :account => 'account', :account_password  => 'account_password', :base_dn => 'base_dn', :encryption  => 'encryption', :method  => 'method', :search_scope  => 'search_scope', :admin_account => 'admin_account', :admin_password=> 'admin_password'}

s = Roo::Excelx.new(file_name)
s.default_sheet = sheet_name
auth_source_infos = []
s.each(columns) do |row|
  licensee_id = format_text(row[:licensee_id])
  next if licensee_id == 'licensee_id'
  auth_source_infos << {:licensee_id => licensee_id,
                        :name => format_text(row[:name]), 
                        :host => format_text(row[:host]),
                        :port => format_text(row[:port]),
                        :account => format_text(row[:account]),
                        :account_password => format_text(row[:account_password]),
                        :base_dn => format_text(row[:base_dn]),
                        :encryption => format_text(row[:encryption]),
                        :method => format_text(row[:method]),
                        :search_scope => format_text(row[:search_scope]),
                        :admin_account => format_text(row[:admin_account]),
                        :admin_password => format_text(row[:admin_password]),
                        :auth_type => "AuthSourceLdap"}
end
puts "auth_source_info: #{auth_source_infos}"

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp
if prompt.casecmp('Y') == 0
  auth_source_infos.each do |auth_source_info|
    licensee_id = auth_source_info[:licensee_id]
    auth_source_info.delete(:licensee_id)

    auth_source = auth_sources_table.where(:host => auth_source_info[:host]).first
    if auth_source.empty?
      auth_source_id = auth_sources_table.insert(auth_source_info)
    else
      auth_source_id = auth_source[:id]
      auth_sources_table.where(:host => auth_source_info[:host]).update(auth_source_info)
    end

    if licensee_table.where(id: licensee_id).count == 0
      raise "licensee[#{licensee_id}] not exist"
    end
    licensee_table.where(id: licensee_id).update(:auth_source_id => auth_source_id, :updated_at => Time.now.utc)
  end
end
