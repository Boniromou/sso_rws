require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 1
  puts "Usage: ruby script/migrate_domain_licensee.rb <env>"
  puts "Example: ruby script/migrate_domain_licensee.rb development"
  Process.exit
end
Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp

exit unless prompt.casecmp('Y') == 0
db[:licensees].where('domain_id is not null').each do |lic|
  if db[:domain_licensees].where(:domain_id => lic[:domain_id], :licensee_id => lic[:id]).count == 0
    db[:domain_licensees].insert(:domain_id => lic[:domain_id], :licensee_id => lic[:id], :created_at => Time.now.utc, :updated_at => Time.now.utc)
  end
end
