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
licensees = config_data['licensees']

sso_db = Database.connect(env)
domain_table = sso_db[:domains]
licensee_table = sso_db[:licensees]

domain_info = []
if domains
  domains.each do |domain|
    domain_info.push({:id => domain['id'], :name => domain['name']})
  end
end
puts "domain_info: #{domain_info}"
puts "licensee_info: #{licensees}"

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp
if prompt.casecmp('Y') == 0
  domain_info.each do |domain|
    domain_table.insert(domain.merge(:created_at => Time.now.utc, :updated_at => Time.now.utc)) if domain_table.where(domain).count == 0
  end

  if licensees
    licensees.each do |licensee|
      if licensee_table.where(id: licensee['id']).count == 0
        raise "update domain-licensee mapping error: licensee[#{licensee['id']}] not exist."
      end
      licensee_table.where(id: licensee['id']).update(domain_id: licensee['domain_id'])
    end
  end
end
