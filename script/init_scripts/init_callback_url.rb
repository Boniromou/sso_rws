require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'

if ARGV.length != 2
  puts "Usage: ruby script/init_scripts/init_callback_url.rb <env> <file_name>"
  puts "Example: ruby script/init_scripts/init_callback_url.rb development config/callback_urls.yml"
  Process.exit
end
Dir[File.expand_path("../utils/*.rb",File.dirname( __FILE__))].each { |file| require file }
db = Database.connect(ARGV[0])
configs = YAML.load_file(ARGV[1])[ARGV[0]]

p configs

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp

exit unless prompt.casecmp('Y') == 0

app_types = {
  'user_management' => 'standard',
  'gaming_operation' => 'standard',
  'cage' => 'standard',
  'station_management' => 'standard',
  'game_recall' => 'standard',
  'signature_verifier' => 'standard',
  'audit_portal' => 'standard',
  'asset_management' => 'standard',
  'trade_promotion' => 'standard',
  'master_data_service' => 'standard',
  'marketing_portal' => 'standard',
  'content_management' => 'standard',
  'spindle' => 'standard',
  'report_portal' => 'standard',
  'platform_game_recall' => 'standard',
  'platform_gaming_operation' => 'vue',
  'kiosk_management' => 'vue',
  'signature_verifier_portal' => 'vue',
  'signature_management' => 'vue',
  'tournament_portal' => 'vue',
  'player_operations_portal' => 'vue',
  'player_approval_operations_portal' => 'vue',
  'supervisor_dashboard' => 'vue',
  'game_feeds_portal' => 'vue'

}

configs.each do |app_name, url|
  app = db[:apps].where(name: app_name)
  type = app_types[app_name] || 'standard'
  if app.first
    db[:apps].where(name: app_name).update(callback_url: url, token_type: type, updated_at: Time.now.utc)
  else
    db[:apps].insert(name: app_name, callback_url: url, token_type: type, created_at: Time.now.utc, updated_at: Time.now.utc)
  end
end
