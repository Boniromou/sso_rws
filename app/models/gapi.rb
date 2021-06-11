class Gapi < AuthSource
  def get_url(app_name)
    "#{URL_BASE}/gapi/new?app_name=#{app_name}&second_authorize=false"
  end

  def get_auth_url(app_name)
    "#{URL_BASE}/gapi/new?app_name=#{app_name}&second_authorize=true"
  end

  def login!(username, app_name, casino_ids)
    valid_before_login!(username)
    system_user = SystemUser.find_by_username_with_domain(username)
    authenticate!(username, app_name, 'active', casino_ids)
  end

  def create_user!(username, domain)
    SystemUser.register_without_check!(username, domain)
  end

  def authorize!(usernam, app_name, casino_id, permission)
    valid_before_login!(username)
    system_user = SystemUser.find_by_username_with_domain(username)
    system_user = authenticate_without_cache!(username, app_name, 'active', [casino_id])
    system_user.authorize!(app_name, casino_id, permission)
  end

  private
  def valid_before_login!(username)
    system_user = SystemUser.find_by_username_with_domain(username)
    if system_user.nil?
      Rails.logger.error "SystemUser[username=#{username}] Login failed. Not a registered account"
      raise Rigi::InvalidLogin.new("alert.invalid_login")
    end
  end
end