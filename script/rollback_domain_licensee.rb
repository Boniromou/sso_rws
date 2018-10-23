require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 1
  puts "Usage: ruby script/rollback_domain_licensee.rb <env>"
  puts "Example: ruby script/rollback_domain_licensee.rb development"
  Process.exit
end
Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp

exit unless prompt.casecmp('Y') == 0
db[:domain_licensees].all.each do |lic|
  db[:licensees].where(:id => lic[:licensee_id]).update(:domain_id => lic[:domain_id], :updated_at => Time.now.utc)
end
