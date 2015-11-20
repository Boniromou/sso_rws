class Internal::SystemUserSessionsController < ApplicationController
  skip_before_filter :authenticate_system_user!

  respond_to :json

  def create
    username = params[:system_user][:username]
    password = params[:system_user][:password]
    app_name = params[:app_name]
    auth_source = AuthSource.find_by_id(AUTH_SOURCE_ID)
    sys_usr = SystemUser.where(:username => username, :auth_source_id => auth_source.id).first
    message = ''
    success = false

    if sys_usr.blank?
      message = "alert.invalid_login"
      Rails.logger.info "SystemUser[username=#{username}][auth_source_name=#{auth_source.name}] Login failed. Not a registered account"
    elsif !sys_usr.is_admin? && !sys_usr.role_in_app(app_name)
      message = "alert.account_no_role"
      Rails.logger.info "SystemUser[username=#{username}][auth_source_name=#{auth_source.name}] Login failed. No role assiged"
    else
      auth_source = auth_source.becomes(auth_source.auth_type.constantize)

      if auth_source.authenticate(sys_usr.login, password)
        sys_usr.update_ad_profile

        if !sys_usr.activated?
          message = "alert.inactive_account"
          Rails.logger.info "SystemUser[username=#{username}][auth_source_name=#{auth_source.name}] Login failed. Inactive_account"
        else
          message = "success"
          success = true
          sys_usr.cache_info(app_name)
        end
      else
        message = "alert.invalid_login"
        Rails.logger.info "SystemUser[username=#{username}][auth_source_name=#{auth_source.name}] Login failed. Authentication failed"
      end
    end

    respond_to do |format|
      format.json { render :json => {:success=>success, :message => message, :system_user => sys_usr}, :status => 200 }
    end
  end
end
