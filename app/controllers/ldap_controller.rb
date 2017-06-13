class LdapController < ApplicationController
  layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
    @app_name = params[:app_name]
    render :template => "system_user_sessions/ldap_new"
  end

  def login
    auth_source = AuthSource.find_by_token(request.remote_ip)
    system_user = auth_source.login!(params[:system_user][:username], params[:system_user][:password], params[:app_name])
	  write_authenticate(system_user)
    redirect_to App.find_by_name(params[:app_name]).callback_url
  rescue Rigi::InvalidLogin => e
    @app_name = params[:app_name]
    flash[:alert] = I18n.t(e.error_message)
    render :template => "system_user_sessions/ldap_new"
  end
end
