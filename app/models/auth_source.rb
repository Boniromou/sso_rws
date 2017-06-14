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

  def self.insert(params)
    params = strip_whitespace(params)
    params[:auth_type] = AuthSourceLdap.to_s
    create!(params)
  end

  def self.edit(params)
    auth_source = find_by_id(params[:id])
    if auth_source
      auth_source.update_attributes!(strip_whitespace(params))
    else
      auth_source = insert(params)
    end
    auth_source
  end

  def self.strip_whitespace(params)
    Hash[params.collect{|k,v| [k, v.to_s.strip]}]
  end

  private
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
