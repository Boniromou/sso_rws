class App < ActiveRecord::Base
  validates_presence_of :name
  attr_accessible :name
  has_many :roles
  has_many :app_system_users
  has_many :system_users, :through => :app_system_users
  has_many :permissions

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
