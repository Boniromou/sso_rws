require 'yaml'
require 'json'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/init_scripts/init_auth_source.rb <env> <file_name>"
  puts "Example: ruby script/init_scripts/init_auth_source.rb development config/adfs.yml"
  Process.exit
end
Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])
configs = YAML.load_file(ARGV[1])[ARGV[0]]

p configs

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp
exit unless prompt.casecmp('Y') == 0

configs.each do |_, config|
  auth_src = db[:auth_sources].where(:token => config['auth_source']['token']).first
  auth_src_dtl = db[:auth_source_details].where(:name => config['auth_source_detail']['name']).first

  db.transaction do
    if auth_src_dtl
      auth_src_dtl_id = auth_src_dtl[:id]
      db[:auth_source_details].where(:id => auth_src_dtl[:id]).update(
        :data => config['auth_source_detail']['data'].to_json,
        :updated_at => Time.now.utc
      )
    else
      auth_src_dtl_id = db[:auth_source_details].insert(
        :name => config['auth_source_detail']['name'],
        :data => config['auth_source_detail']['data'].to_json,
        :created_at => Time.now.utc,
        :updated_at => Time.now.utc
      )
    end

    if auth_src
      db[:auth_sources].where(:id => auth_src[:id]).update(
        :type => config['auth_source']['type'],
        :auth_source_detail_id => auth_src_dtl_id
      )
    else
      db[:auth_sources].insert(
        :token => config['auth_source']['token'],
        :type => config['auth_source']['type'],
        :auth_source_detail_id => auth_src_dtl_id
      )
    end
  end
end
