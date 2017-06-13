require 'yaml'
require 'json'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/init_ldap.rb <env> <file_name>"
  puts "Example: ruby script/init_ldap.rb development config/ldap.yml"
  Process.exit
end
Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])
configs = YAML.load_file(ARGV[1])[ARGV[0]]

p configs

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp

if prompt.casecmp('Y') == 0
  configs.each do |_, config|
    auth_src_dtl = db[:auth_source_details].where(:name => config['auth_source_detail']['name'])
    db.transaction do
      auth_src_id = db[:auth_sources].insert(:token => config['auth_source']['token'],
                                             :type => config['auth_source']['type'])
      auth_src_dtl_id = db[:auth_source_details].insert(:name => config['auth_source_detail']['name'],
                                                        :data => config['auth_source_detail']['data'].to_json,
                                                        :created_at => Time.now.utc,
                                                        :updated_at => Time.now.utc)
      db[:domains].where(:name => config['domain']['name']).update(:auth_source_detail_id => auth_src_dtl_id)
    end
  end
end
