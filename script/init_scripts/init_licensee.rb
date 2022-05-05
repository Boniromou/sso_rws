require 'sequel'
require 'json'
require 'yaml'
require 'logger'

env = ARGV[0]
licensee_id= ARGV[1]
if env.nil? || licensee_id.nil?
  puts "Usage: ruby xxx.rb [env] [licensee_id]"
  exit
end
licensee_id = licensee_id.to_i

Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])

data = YAML.load_file(File.expand_path(File.dirname(__FILE__)+"/config_files/#{licensee_id}.yml"))[env]
data['sync_user_config'] = data['sync_user_config'].to_json
data.merge!({:updated_at=>Time.now.utc})

p data
dataset = db[:licensees]

if dataset.filter(:id=>licensee_id).first
  dataset.filter(:id=>licensee_id).update(data)
else
  dataset.insert(data.merge({:id=>licensee_id,:created_at=>Time.now.utc}))
end

puts 'exit'
