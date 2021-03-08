require 'sequel'
require 'yaml'

if ARGV.length != 2
        puts "Usage: ruby script/init_scripts/disable_root.rb <env> <username>"
        puts "Example: ruby script/init_scripts/disable_root.rb staging0 lucy.cheung"
    Process.exit
end

env = ARGV[0]
username = ARGV[1]

Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])

unless db[:system_users].where(:username => username).first
  p "System User #{username} not found!"
  Process.exit
end

db[:system_users].where(:username => username).update(:admin => false)

p "System User #{username} root disabled successfully!"
