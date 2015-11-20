class SystemUser < ActiveRecord::Base
  devise :registerable
         #:recoverable, :rememberable, :trackable    #, :validatable
  attr_accessible :id, :username, :status, :admin, :auth_source_id#, :sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip#, :password, :encrypted_password
  belongs_to :auth_source
  has_many :role_assignments, :as => :user, :dependent => :destroy
  has_many :roles, :through => :role_assignments
  has_many :app_system_users
  has_many :apps, :through => :app_system_users
  has_many :properties_system_users
  has_many :properties, :through => :properties_system_users

  def active_property_ids
    PropertiesSystemUser.where(:system_user_id => id, :status => true).select(:property_id).pluck(:property_id)
  end

  def is_internal?
    auth_source.is_internal?
  end

  def is_admin?
    admin
  end

  alias_method "is_root?", "is_admin?"

  def activated?
    self.status
  end

  def self.inactived
    where("status = ?", "inactived")
  end

  def update_roles(role_ids)
    existing_roles = self.role_assignments.map { |role_assignment| role_assignment.role_id }
    diff_role_ids = self.class.diff(existing_roles, role_ids)

    transaction do
      diff_role_ids.each do |role_id|
        if existing_roles.include?(role_id)
          revoke_role(role_id)
        elsif 
          assign_role(role_id)
        end
      end
    end
    
  end

  def self.get_by_username_and_domain(username, domain)
    self.joins(:auth_source).where("auth_sources.domain" => domain, :username => username).first
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

    nil
  end

  # determine if the user has permission on a particular action (in this app by default)
  def has_permission?(target, action, app_name=APP_NAME)
    role = role_in_app(app_name)
    role && role.has_permission?(target, action)
  end

  def cache_info(app_name)
    cache_profile
    cache_permissions(app_name) unless is_admin?
  end

  def lock
    update_attributes({:status => 0})
    cache_profile
  end

  def unlock
    update_attributes({:status => 1})
    cache_profile
  end

  def cache_revoke_permissions(app_name)
    cache_key = "#{app_name}:permissions:#{self.id}"
    Rails.cache.delete(cache_key)
  end

  def update_properties(property_ids)
    PropertiesSystemUser.update_properties_by_system_user(id, property_ids)
  end

  def update_ad_profile
    profile = 
      if is_internal?
        Rigi::Ldap.retrieve_user_profile(username)
      else
        property_ids = Property.select(:id).pluck(:id)
        Rigi::Ldap.retrieve_user_profile(username, property_ids)
      end
    
    user_properties = is_internal? ? [INTERNAL_PROPERTY_ID] : profile[:groups]
    self.status = profile[:account_status]
    update_properties(user_properties)
    save!
  end

  private
  # a = [2, 4, 6, 8]
  # b = [1, 2, 3, 4]
  #  => [6, 8, 1, 3]
  def self.diff(x,y)
    o = x
    x = x.reject{|a| if y.include?(a); a end }
    y = y.reject{|a| if o.include?(a); a end }
    x | y
  end

  def assign_role(role_id)
    Rails.logger.info "Grant role (id=#{role_id}) for #{self.class.name} (id=#{self.id})"
    self.role_assignments.create({:role_id => role_id})
    role = Role.find_by_id(role_id)
    add_app_assignment(role.app_id)
    app = App.find_by_id(role.app_id)
    cache_permissions(app.name) if app
  end

  def revoke_role(role_id)
    Rails.logger.info "Revoke role (id=#{role_id}) for #{self.class.name} (id=#{self.id})"
    self.role_assignments.find_by_role_id(role_id).destroy
    role = Role.find_by_id(role_id)
    app = App.find_by_id(role.app_id)
    remove_app_assignment(role.app_id)
    cache_revoke_permissions(app.name) if app
  end

  def add_app_assignment(app_id)
    Rails.logger.info "Assign App (id=#{app_id}) for #{self.class.name} (id=#{self.id})"
    self.app_system_users.create({:app_id => app_id})
  end

  def remove_app_assignment(app_id)
    Rails.logger.info "Remove App (id=#{app_id}) for #{self.class.name} (id=#{self.id})"
    self.app_system_users.find_by_app_id(app_id).destroy
  end

  def cache_profile
    cache_key = "#{self.id}"
    cache_hash = {:status => self.status, :admin => self.admin, :properties => self.active_property_ids}
    Rails.cache.write(cache_key, cache_hash)
  end

  def cache_permissions(app_name)
    cache_key = "#{app_name}:permissions:#{self.id}"
    role = role_in_app(app_name)
    return unless role
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
end
