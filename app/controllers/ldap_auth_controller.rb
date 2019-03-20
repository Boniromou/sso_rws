class LdapAuthController < ApplicationController
  layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
    check_login_type!('Ldap')
    @app_name = params[:app_name]
  end

  def create
    auth_source = AuthSource.find_by_token(get_client_ip)
    system_user = auth_source.authorize!(params[:system_user][:username], params[:system_user][:password], params[:app_name], auth_info['casino_id'], auth_info['permission'])
    Rails.logger.info 'Authorize successfully.'
    write_authorize_cookie({error_code: 'OK', error_message: 'Authorize successfully.', authorized_by: params[:system_user][:username], authorized_at: Time.now})
    redirect_to auth_info['callback_url']
  rescue Rigi::InvalidLogin => e
    @app_name = params[:app_name]
    flash[:alert] = I18n.t(e.error_message)
    render :template => "ldap_auth/new"
  rescue Rigi::InvalidAuthorize => e
    Rails.logger.error "Authorize failed: #{e.error_message}"
    write_authorize_cookie({error_code: 'InvalidAuthorize', error_message: e.error_message})
    redirect_to auth_info['callback_url']
  end

  private
  def auth_info
    JSON.parse cookies[:second_auth_info]
  end
end
