class LdapController < ApplicationController
	layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
  	@app_name = params[:app_name]
  	render :template => "system_user_sessions/ldap_new"
  end
end