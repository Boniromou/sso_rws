require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'
Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }

if ARGV.length != 2
  puts "Usage: ruby script/init_domain.rb <env> <file_name>"
  puts "Example: ruby script/init_domain.rb development config/domain.yml"
  Process.exit
end

env = ARGV[0]
file_name = ARGV[1]
config_data = YAML.load_file(file_name)[env]
domains = config_data['domains']

sso_db = Database.connect(env)
domain_table = sso_db[:domains]

if domains
  domain_info = []
  domains.each do |domain|
    domain_info.push({:id => domain['id'], :name => domain['name'], :licensee_id => domain['licensee_id']})
  end
end
puts "domain_info: #{domain_info}"

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp
if prompt.casecmp('Y') == 0
  domain_info.each do |domain|
    domain_condition = {:id => domain[:id], :name => domain[:name]}
    if domain_table.where(domain_condition).count == 0
      domain_table.insert(domain.merge(:created_at => Time.now.utc, :updated_at => Time.now.utc))
    else
      domain_table.where(domain_condition).update(:licensee_id => domain[:licensee_id], :updated_at => Time.now.utc)
    end
  end
end
