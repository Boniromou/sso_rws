class App < ActiveRecord::Base
  has_many :roles
  has_many :app_system_users
  has_many :system_users, :through => :app_system_users
  has_many :permissions

=begin
  def self.permissions(app_id)
    perm_hash ={}
    app = self.find_by_id(app_id)
    app.roles.each do |role|
      permissions = role.permissions
      permissions.each do |perm|
        perms = perm_hash.has_key?(perm.target.to_sym) ? perm_hash[perm.target.to_sym] : {}
        perms[perm.action.to_sym] = perm.name
        perm_hash[perm.target.to_sym] = perms
      end
    end
    perm_hash
  end
=end
  def permissions_with_groups
    perm_hash = {}

    permissions.each do |perm|
      perms = perm_hash.has_key?(perm.target.to_sym) ? perm_hash[perm.target.to_sym] : {}
      perms[perm.action.to_sym] = perm.name
      perm_hash[perm.target.to_sym] = perms
    end

    perm_hash
  end

  def self.get_all_apps
    App.all.map {|app| {app.id => app.name.titleize}}.inject(:merge) || {}
  end
end
