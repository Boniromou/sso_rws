class Gapi < AuthSource
  def get_url(app_name)
    "#{URL_BASE}/gapi/new?app_name=#{app_name}&second_authorize=false"
  end

  def get_auth_url(app_name)
    "#{URL_BASE}/gapi_auth/new?app_name=#{app_name}&second_authorize=true"
  end

  def authenticate!(username, app_name, casino_ids, session_token)
    system_user = valid_before_login!(username)
    casino_ids = system_user.domain.get_casino_ids & casino_ids
    super(username, app_name, SystemUser::ACTIVE, casino_ids, session_token)
  end

  def create_user!(username, domain)
    SystemUser.register_without_check!(username, domain)
  end

  def authorize!(username, app_name, casino_id, permission)
    system_user = valid_before_login!(username)
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
    system_user
  end
end
