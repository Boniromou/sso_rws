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

  def role_in_app
    app = App.find_by_name(APP_NAME)
    self.roles.each do |role|
      if role.app.id == app.id
	return role
      end
    end
  end
end
