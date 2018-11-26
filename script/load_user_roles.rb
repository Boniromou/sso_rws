require 'roo'
require 'yaml'
require 'fileutils'
require 'sequel'
require 'logger'
require 'active_support/core_ext/hash'

Dir[File.expand_path("./utils/*.rb",File.dirname( __FILE__))].each { |file| require file }

class UserHelper
  def initialize(env)
    Sequel.extension(:pg_json)
    @db = Database.connect(env)
  end

  def get_user_info(file_name)
    xlsx = Roo::Excelx.new(file_name)
    xlsx.default_sheet = xlsx.sheets[0]
    xlsx.parse(get_header(xlsx)).map{|user| {user['user_name'] => user.except('user_name')}}.inject(:merge)
  end

  def upload(user_info)
    prepare_app_roles
    user_info.each do |user, app_roles|
      system_user = get_system_user(user)
      diff_roles = compare_user_roles(app_roles, system_user[:id])
      next if diff_roles.size == 0
      update_roles(system_user, diff_roles)
      create_edit_role_change_log(system_user, diff_roles)
    end
  end

  private
  def get_header(xlsx)
    cols = {}
    (1..xlsx.last_column).each do |col_index|
      col = xlsx.column(col_index)[0]
      cols[col] = col
    end
    cols.delete_if { |key, value| value == '' }
  end

  def prepare_app_roles
    @apps = @db[:apps].select_hash(:name, :id)
    role_data = @db[:roles].to_hash_groups(:app_id, [:name, :id])
    @role_data = role_data.map {|app_id, roles| {app_id => Hash[roles]}}.inject(:merge)
  end

  def compare_user_roles(app_roles, user_id)
    diff_roles = {}
    app_roles.each do |app, role|
      app_id = @apps[app]
      from_roles = @db[:role_assignments].join(@db[:roles].as(:roles), id: :role_assignments__role_id).where(roles__app_id: app_id, role_assignments__user_id: user_id).select_map(:roles__id)
      to_roles = get_role_ids(app_id, role)
      next if (from_roles - to_roles | to_roles - from_roles).empty?
      diff_roles[app_id] = { from_roles: from_roles, to_roles: to_roles }
    end
    return diff_roles
  end

  def get_role_ids(app_id, roles)
    return [] if roles == '-' || roles == ''
    role_ids = []
    roles.split(',').each do |role|
      raise "role[#{role}] not found in app[#{app_id}]." unless @role_data[app_id][role]
      role_ids << @role_data[app_id][role]
    end
    role_ids
  end

  def get_system_user(username_with_domain)
    username, domain = username_with_domain.split('@', 2)
    domain = @db[:domains].first(name: domain)
    @db[:system_users].first(username: username, domain_id: domain[:id])
  end

  def update_roles(user, diff_roles)
    @db.transaction do
      diff_roles.each do |app_id, diff_role|
        (diff_role[:to_roles] - diff_role[:from_roles] | diff_role[:from_roles] - diff_role[:to_roles]).each do |role_id|
          diff_role[:from_roles].include?(role_id) ? revoke_role(user, app_id, role_id) : assign_role(user, app_id, role_id)
        end
        diff_role[:to_roles].size > 0 ? add_app_user(user, app_id) : remove_app_user(user, app_id)
      end
    end
  end

  def assign_role(user, app_id, role_id)
    @db[:role_assignments].insert(user_type: 'SystemUser', user_id: user[:id], role_id: role_id, created_at: Time.now.utc, updated_at: Time.now.utc)
  end

  def revoke_role(user, app_id, role_id)
    @db[:role_assignments].where(user_id: user[:id], role_id: role_id).delete
  end

  def add_app_user(user, app_id)
    @db[:app_system_users].insert(system_user_id: user[:id], app_id: app_id, created_at: Time.now.utc, updated_at: Time.now.utc) if @db[:app_system_users].where(system_user_id: user[:id], app_id: app_id).count == 0
  end

  def remove_app_user(user, app_id)
    @db[:app_system_users].where(system_user_id: user[:id], app_id: app_id).delete
  end

  def create_edit_role_change_log(user, diff_roles)
    diff_roles.each do |app_id, diff_role|
      change_detail = {
        app_name: @db[:apps].first(id: app_id)[:name],
        from: get_role_names(diff_role[:from_roles]),
        to: get_role_names(diff_role[:to_roles])
      }
      create_change_log(change_detail, user)
    end
  end

  def create_change_log(change_detail, target_user)
    time_now = Time.now.utc
    change_log_info = {
      type: 'SystemUserChangeLog',
      target_username: target_user[:username],
      target_domain: @db[:domains].first(id: target_user[:domain_id])[:name],
      action: 'edit_role',
      action_by: {'username' => 'system'}.to_json,
      change_detail: change_detail.to_json,
      created_at: time_now,
      updated_at: time_now
    }
    change_log = @db[:change_logs].insert(change_log_info)
    create_target_casinos(change_log, target_user)
  end

  def create_target_casinos(change_log, target_user)
    casinos = @db[:casinos_system_users].join(@db[:casinos].as(:casinos), id: :casinos_system_users__casino_id).where(casinos_system_users__system_user_id: target_user[:id], casinos_system_users__status: 1).select(:casinos__id, :casinos__name)
    casinos.each do |casino|
      @db[:target_casinos].insert(change_log_id: change_log, target_casino_id: casino[:id], target_casino_name: casino[:name])
    end
  end

  def get_role_names(role_ids)
    return nil if role_ids.size == 0
    roles = @db[:roles].where(id: role_ids).select(:name)
    roles.map{|role| role[:name] }.join(',')
  end
end

if ARGV.length != 2
  puts "Usage: ruby script/load_user_roles.rb <env> <file_name>"
  puts "Example: ruby script/load_user_roles.rb development script/config_files/system_user_list.xlsx"
  Process.exit
end

user_helper = UserHelper.new(ARGV[0])
users = user_helper.get_user_info(ARGV[1])
p '---------------------------------------------------'
p 'found users:'
p users
p '---------------------------------------------------'

print "Overwrite? (Y/n): "
prompt = STDIN.gets.chomp
exit unless prompt.casecmp('Y') == 0

user_helper.upload(users)
