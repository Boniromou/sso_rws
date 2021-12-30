require 'yaml'
require 'json'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length < 1
  puts "Usage: ruby script/init_scripts/setup.rb <env> <file_name>"
  puts "Example: ruby script/init_scripts/setup.rb development config/setup.yml"
  Process.exit
end

env = ARGV[0]
file_name = ARGV[1] || File.expand_path(File.dirname(__FILE__)) + "/../config_files/#{env}.yml"
config_data = YAML.load_file(file_name)

Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
$db = Database.connect(env)

def insert_db(db_name, data, key = 'id', time = true)
  p "insert #{db_name}: [#{data}]"
  data.merge!({created_at: Time.now.utc, updated_at: Time.now.utc}) if time
  $db[db_name].insert(data) if $db[db_name].where(key.to_sym => data[key]).count == 0
end

config_data = YAML.load_file(file_name)
config_data['auth_source_detail']['data'] = config_data['auth_source_detail']['data'].to_json

insert_db(:apps, config_data['app'], 'name')
insert_db(:auth_sources, config_data['auth_source'], 'id', false)
insert_db(:auth_source_details, config_data['auth_source_detail'])
insert_db(:domains, config_data['domain'])
insert_db(:domain_licensees, config_data['domain_licensee'])
insert_db(:system_users, config_data['user'])
