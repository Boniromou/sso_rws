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
=begin
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
=end
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
    return nil
  end

  def cache_info(app_name)
    cache_status
    cache_permissions(app_name) unless is_admin?
  end

  def lock
    update_attributes({:status => 0})
    cache_status
  end

  def unlock
    update_attributes({:status => 1})
    cache_status
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
  end

  def revoke_role(role_id)
    Rails.logger.info "Revoke role (id=#{role_id}) for #{self.class.name} (id=#{self.id})"
    self.role_assignments.find_by_role_id(role_id).destroy
    role = Role.find_by_id(role_id)
    remove_app_assignment(role.app_id)
  end

  def add_app_assignment(app_id)
    Rails.logger.info "Assign App (id=#{app_id}) for #{self.class.name} (id=#{self.id})"
    self.app_system_users.create({:app_id => app_id})
  end

  def remove_app_assignment(app_id)
    Rails.logger.info "Remove App (id=#{app_id}) for #{self.class.name} (id=#{self.id})"
    self.app_system_users.find_by_app_id(app_id).destroy
  end

  def cache_status
    cache_key = "#{self.id}"
    cache_hash = {:status => self.status, :admin => self.admin}
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
