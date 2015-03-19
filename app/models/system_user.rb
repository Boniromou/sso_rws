class SystemUser < ActiveRecord::Base
  devise :registerable
         #:recoverable, :rememberable, :trackable    #, :validatable
  attr_accessible :username, :status, :admin, :auth_source_id#, :sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip#, :password, :encrypted_password
  belongs_to :auth_source
  has_many :role_assignments, :as => :user, :dependent => :destroy
  has_many :roles, :through => :role_assignments
  has_many :app_system_users
  has_many :apps, :through => :app_system_users

  def is_admin?
    admin
  end

  alias_method "is_root?", "is_admin?"

  def activated?
    self.status
  end

  def update_roles(role_id)
    unless role_id.blank?
      if role_id.to_i > 0
        if self.roles.blank?
	  self.role_assignments.create({:role_id => role_id})
	else
	  if self.role_assignments[0].role_id.to_i != role_id.to_i
	    self.role_assignments[0].role_id = role_id
	    self.role_assignments[0].save!
	  end
        end
      elsif role_id.to_i == -1
	if !self.role_assignments[0].blank?
	  self.role_assignments[0].destroy
	end
      end
    end
  end

  def self.get_by_username_and_domain(username, domain)
    SystemUser.joins(:auth_source).where("auth_sources.domain" => domain, :username => username).first
  end

  # username for login
  def login
    self.auth_source.domain ? "#{self.auth_source.domain}\\#{self.username}" : self.username
  end

  def role_in_app(app_name=nil)
    app_name = app_name || APP_NAME
    app = App.find_by_name(app_name)
    self.roles.each do |role|
      if role.app.id == app.id
	return role
      end
    end
  end

  def cache_info(app_name)
    cache_status
    cache_permissions(app_name) unless is_admin?
  end

  def cache_status
    cache_key = "#{self.id}"
    cache_hash = {}
    cache_hash[cache_key] = {:status => self.status, :admin => self.admin}
    Rails.cache.write(cache_key, cache_hash)
  end

  def cache_permissions(app_name)
    cache_key = "#{app_name}:permissions:#{self.id}"
    role = role_in_app(app_name)
    permissions = role.permissions
    targets = permissions.map{|x| x.target}.uniq
    perm_hash = {}
    targets.each do |t|
      actions = []
      permissions.each do |perm|
	if perm.target == t
	  actions << perm.action
	end
      end
      perm_hash[t.to_sym] = actions
    end
    Rails.cache.write(cache_key, {:permissions => {:role => role.name, :permissions => perm_hash}})
  end

  def lock
    update_attributes({:status => 0})
    cache_status 
  end
  
  def unlock
    update_attributes({:status => 1})
    cache_status
  end
end
