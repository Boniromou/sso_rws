require 'sequel'
require 'json'
require 'yaml'
require 'logger'
require 'csv'


if ARGV.length != 2
  puts "Usage: ruby script/init_scripts/add_token.rb <env> <file_name>"
  puts "Example: ruby script/init_scripts/add_token.rb development config/token.csv"
  Process.exit
end

Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])
datas = CSV.read(ARGV[1], :headers => true)

count = 0
datas.each do |data|
  data = data.to_hash
  next if db[:auth_sources].where(token: data['token'], type: data['type']).first
  db[:auth_sources].insert(data)
  count += 1
end

p "import tokens size: #{count}"

puts 'exit'
