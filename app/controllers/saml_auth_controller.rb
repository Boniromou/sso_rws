class SamlAuthController < SamlController
  skip_before_filter :authenticate_system_user!, :check_activation_status
  rescue_from Rigi::InvalidLogin, Rigi::InvalidAuthorize, :with => :handle_invalid_login

  def get_saml_settings
    settings = AuthSource.find_by_token(get_client_ip).get_saml_settings(get_url_base, app_name)
    settings.issuer = get_url_base + "/saml_auth/metadata"
    settings.assertion_consumer_service_url = get_url_base + "/saml_auth/acs?app_name=#{app_name}"
    settings.assertion_consumer_logout_service_url = get_url_base + "/saml_auth/logout?app_name=#{app_name}"
    settings
  end

  def authenticate!(username, app_name, casino_ids)
    system_user = AuthSource.find_by_token(get_client_ip).authorize!(username, app_name, casino_ids, auth_info['casino_id'], auth_info['permission'])
    Rails.logger.info("Login in success")
    write_authorize_cookie({error_code: 'OK', error_message: 'Authorize successfully.', authorized_by: username, authorized_at: Time.now})
    redirect_to auth_info['callback_url']
  end

  private
  def redirect_to_logout_path
    redirect_to "#{URL_BASE}/saml_auth/logout/?slo=true&app_name=#{app_name}"
  end

  def auth_info
    JSON.parse cookies[:second_auth_info]
  end

  def handle_invalid_login(e)
    Rails.logger.error e.error_message
    Rails.logger.error e.backtrace
    write_authorize_cookie({error_code: e.message, error_message: e.error_message})
    redirect_to auth_info['callback_url']
  end
end
