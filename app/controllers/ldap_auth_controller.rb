class LdapAuthController < ApplicationController
  layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
    check_login_type!('Ldap')
    @app_name = params[:app_name]
  end

  def second_authorize
    auth_source = AuthSource.find_by_token(get_client_ip)
    system_user = auth_source.authorize!(params[:system_user][:username], params[:system_user][:password], params[:app_name], auth_info['casino_id'], auth_info['permission'])
    write_cookie(:second_auth_result, {error_code: 'OK', error_message: 'Authorize successfully.'})
    redirect_to auth_info['callback_url']
  rescue Rigi::InvalidLogin => e
    @app_name = params[:app_name]
    flash[:alert] = I18n.t(e.error_message)
    render :template => "ldap_auth/new"
  rescue Rigi::InvalidAuthorize => e
    Rails.logger.error e.error_message
    write_cookie(:second_auth_result, {error_code: 'InvalidAuthorize', error_message: e.error_message})
    redirect_to auth_info['callback_url']
  end

  private
  def auth_info
    JSON.parse cookies[:second_auth_info]
  end
end
