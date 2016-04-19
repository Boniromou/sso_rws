require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/init_licensee_casino_property.rb env <file_name>"
  puts "Example: ruby script/init_licensee_casino_property.rb development config/licensee_casino_property.yml"
  Process.exit
end

env= ARGV[0]
file_name = ARGV[1]
config_data = YAML.load_file(file_name)[env]

licensees       = config_data['licensees']
casinos         = config_data['casinos']
properties      = config_data['properties']

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

if licensees
  licensee_info = []
  licensees.each do |licensee|
    licensee_info.push({:id => licensee['id'],:name => licensee['name']})
  end
end

if casinos
  casino_info = []
  casinos.each do |casino|
    casino_info.push({:id => casino['id'], :licensee_id => casino['licensee_id'], :name => casino['name']})
  end
end

if properties
  property_info = []
  properties.each do |property|
    property_info.push({:id => property['id'], :casino_id => property['casino_id'], :name => property['name']})
  end
end

licensee_table       = sso_db[:licensees]
casino_table         = sso_db[:casinos]
property_table       = sso_db[:properties]

licensee_info.each do |licensee|
  licensee_table.insert(licensee.merge(:created_at => Time.now.utc, :updated_at => Time.now.utc)) if licensee_table.where(licensee).count == 0
end

casino_info.each do |casino|
  casino_table.insert(casino.merge(:created_at => Time.now.utc, :updated_at => Time.now.utc)) if casino_table.where(casino).count == 0
end

property_info.each do |property|
  property_obj = property_table.where(:id => property[:id])
  if property_obj.count != 0
    property_obj.update(:name => property[:name], :description => "",:casino_id => property[:casino_id]) 
  else
    property_table.insert(property.merge(:created_at => Time.now.utc, :updated_at => Time.now.utc))
  end
end
property_table.where(:id => 30000).delete()





