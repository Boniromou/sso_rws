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

RAILS_ROOT = File.expand_path(File.dirname(__FILE__)+"/../") unless defined?(RAILS_ROOT)
db_config = YAML.load_file("#{RAILS_ROOT}/config/database.yml")[env]
DB = Sequel.connect(sprintf('%s://%s:%s@%s:%s/%s',
                           db_config['adapter'],
                           db_config['username'],
                           db_config['password'],
                           db_config['host'],
                           db_config['port'] || 3306,
                           db_config['database']),
                           :loggers=>[Logger.new($stdout)])

data = YAML.load_file(File.expand_path(File.dirname(__FILE__)+"/config_files/#{licensee_id}.yml"))[env]
data['sync_user_config'] = data['sync_user_config'].to_json
data.merge!({:updated_at=>Time.now.utc})

p data
dataset = DB[:licensees]

if dataset.filter(:id=>licensee_id).first
  dataset.filter(:id=>licensee_id).update(data)
else
  dataset.insert(data.merge({:id=>licensee_id,:created_at=>Time.now.utc}))
end

puts 'exit'

