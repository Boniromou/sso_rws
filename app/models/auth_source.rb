class AuthSource < ActiveRecord::Base
  attr_accessible :type
  belongs_to :auth_source_detail

  def authenticate!(username, app_name, status, casino_ids)
    system_user = SystemUser.find_by_username_with_domain(username)
    system_user.update_user_profile(status, casino_ids)
    validate_role_status!(system_user, app_name)
    validate_account_status!(system_user)
    validate_account_casinos!(system_user)
    system_user.cache_info(app_name)
    system_user.insert_login_history(app_name)
    system_user
  end

  def self.create_system_user!(username, domain)
    validate_before_create_user!(username, domain)
    domain_obj = Domain.where(:name => domain).first
    if domain_obj.auth_source_detail
      Ldap.new.create_ldap_user!(username, domain)
    else
      Adfs.new.create_adfs_user!(username, domain)
    end
  end

  private
  def self.validate_before_create_user!(username, domain)
    SystemUser.validate_username!(username)
    Domain.validate_domain!(domain)
    domain_obj = Domain.where(:name => domain).first
    sys_usr = SystemUser.where(:username => username, :domain_id => domain_obj.id).first
    raise Rigi::RegisteredAccount.new(I18n.t("alert.registered_account")) if sys_usr
  end

  def validate_role_status!(system_user, app_name)
    unless system_user.is_admin? || system_user.role_in_app(app_name)
      Rails.logger.error "SystemUser[username=#{system_user.username}] Login failed. No role assigned"
      raise Rigi::InvalidLogin.new("alert.account_no_role")
    end
  end

  def validate_account_status!(system_user)
    if !system_user.activated?
      Rails.logger.error "SystemUser[username=#{system_user.username}] Login failed. Inactive_account"
      raise Rigi::InvalidLogin.new("alert.inactive_account")
    end
  end

  def validate_account_casinos!(system_user)
    if !system_user.is_admin? && system_user.active_casino_ids.blank?
      Rails.logger.error "SystemUser[username=#{system_user.username}] Login failed. The account has no casinos"
      raise Rigi::InvalidLogin.new("alert.account_no_casino")
    end
  end
end
