class LdapController < ApplicationController
  layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
    check_login_type!('ldap')
    @app_name = params[:app_name]
    render :template => "system_user_sessions/ldap_new"
  end

  def login
    auth_source = AuthSource.find_by_token(get_client_ip)
    session_token = SecureRandom.uuid
    system_user = auth_source.login!(params[:system_user][:username], params[:system_user][:password], params[:app_name], session_token)
    write_authenticate(system_user, params[:app_name], session_token)
    redirect_to App.find_by_name(params[:app_name]).callback_url
  rescue Rigi::InvalidLogin => e
    @app_name = params[:app_name]
    flash[:alert] = I18n.t(e.error_message)
    render :template => "system_user_sessions/ldap_new"
  end
end
