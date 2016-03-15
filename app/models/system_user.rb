class SystemUser < ActiveRecord::Base
  devise :registerable
  attr_accessible :id, :username, :status, :admin, :auth_source_id, :domain_id
  belongs_to :auth_source
  has_many :role_assignments, :as => :user, :dependent => :destroy
  has_many :roles, :through => :role_assignments
  has_many :app_system_users
  has_many :apps, :through => :app_system_users
  belongs_to :domain
  has_many :casinos_system_users
  has_many :casinos, :through => :casinos_system_users
  scope :with_active_casino, -> { joins(:casinos_system_users).where("casinos_system_users.status = ?", true).select("DISTINCT(system_users.id), system_users.*") }

  def auth_source
    auth = AuthSource.find_by_id(auth_source_id)
    auth.becomes(auth.auth_type.constantize)
  end

  def active_casino_ids
    self.casinos_system_users.where(:status => true).pluck(:casino_id)
  end

  def active_casino_id_names
    rtn = []
    self.casinos.each do |casino|
      rtn.push({:id => casino.id, :name => casino.name})
    end
    rtn
  end

  def is_admin?
    admin
  end

  def has_admin_casino?
    active_casino_ids.include?(ADMIN_CASINO_ID)
  end

  def self.register!(username, domain, auth_source_id, casino_ids)
    transaction do
      domain = Domain.where(:name => domain).first
      system_user = create!(:username => username, :domain_id => domain.id, :auth_source_id => auth_source_id, :status => true)
      system_user.update_casinos(casino_ids)
    end
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

    refresh_permission_cache
  end

  def role_in_app(app_name=nil)
    app = App.find_by_name(app_name || APP_NAME)

    self.roles.includes(:app, :role_permissions => :permission).each do |role|
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

=begin
  def lock
    update_attributes({:status => 0})
    cache_profile
  end

  def unlock
    update_attributes({:status => 1})
    cache_profile
  end
=end

  def update_casinos(casino_ids)
    CasinosSystemUser.update_casinos_by_system_user(id, casino_ids)
  end

  def update_ad_profile
    casino_ids = self.domain.get_casino_ids
    profile = self.auth_source.retrieve_user_profile(username, self.domain.name, casino_ids)
    self.status = profile[:status]
    update_casinos(profile[:casino_ids])
    save!
  end

  def refresh_permission_cache
    all_app_ids = App.all
    assigned_app_ids = self.apps(true).map { |app| app.id }

    all_app_ids.each do |existing_app|
      if assigned_app_ids.include?(existing_app.id)
        cache_permissions(existing_app.name)
      else
        cache_revoke_permissions(existing_app.name)
      end
    end
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

  def cache_profile
    cache_key = "#{self.id}"
    casinos = self.active_casino_ids
    properties = Property.where(:casino_id => casino_ids).pluck(:id)
    cache_hash = {
      :status => self.status,
      :admin => self.admin,
      :casinos => casinos,
      :properties => properties
    }
    Rails.cache.write(cache_key, cache_hash)
  end

  def cache_revoke_permissions(app_name)
    cache_key = "#{app_name}:permissions:#{self.id}"
    Rails.cache.delete(cache_key)
  end

  def cache_permissions(app_name)
    cache_key = "#{app_name}:permissions:#{self.id}"
    role = role_in_app(app_name)
    return unless role
    permissions = role.permissions
    targets = permissions.map{|x| x.target}.uniq
    perm_hash = {}
    value_hash = {}

    targets.each do |t|
      actions = []

      permissions.each do |perm|
        if perm.target == t
          actions << perm.action
          role_permission_value = role.get_permission_value(t, perm.action)
          if role_permission_value
            value_hash[t.to_sym] ||= {}
            value_hash[t.to_sym][perm.action.to_sym] = role_permission_value
          end
        end
      end

      perm_hash[t.to_sym] = actions
    end

    Rails.cache.write(cache_key, {:permissions => {:role => role.name, :permissions => perm_hash, :values => value_hash}})
  end
end
