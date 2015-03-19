class Internal::SystemUserSessionsController < ApplicationController
  skip_before_filter :authenticate_system_user!

  respond_to :json

  def create
    username = params[:system_user][:username]
    password = params[:system_user][:password]
    app_name = params[:app_name]
    auth_source = AuthSource.get_default_auth_source
    sys_usr = SystemUser.get_by_username_and_domain(username, auth_source.domain)
    message = ''
    success = false
    if !sys_usr
      message = "alert.invalid_login"
      Rails.logger.info "SystemUser[username=#{username}][domain=#{auth_source.domain}] Login failed. Not a registered account"
    elsif !sys_usr.activated?
       message = "alert.inactive_account"
       Rails.logger.info "SystemUser[username=#{username}][domain=#{auth_source.domain}] Login failed. Inactive_account"
    else
      auth_source = auth_source.becomes(auth_source.auth_type.constantize)
      if auth_source.authenticate(sys_usr.login, password)
        message = "success"
        success = true
 	sys_usr.cache_info(app_name)	
      else
         message = "alert.invalid_login"
         Rails.logger.info "SystemUser[username=#{username}][domain=#{auth_source.domain}] Login failed. Authentication failed"
      end
    end
    respond_to do |format|
      format.json{render :json => {:success=>success, :message => message, :system_user => sys_usr}, :status => 200}
    end
  end
end
