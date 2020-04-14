require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/init_callback_url.rb <env> <file_name>"
  puts "Example: ruby script/init_callback_url.rb development config/callback_urls.yml"
  Process.exit
end
Dir[File.expand_path("utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])
configs = YAML.load_file(ARGV[1])[ARGV[0]]

p configs

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp

if prompt.casecmp('Y') == 0
  configs.each do |app_name, url|
    app = db[:apps].where(:name => app_name)
    if app.first
      app.update(:callback_url => url, :updated_at => Time.now.utc)
    else
      db[:apps].insert(:name => app_name, :callback_url => url, :created_at => Time.now.utc, :updated_at => Time.now.utc)
    end
  end
end
