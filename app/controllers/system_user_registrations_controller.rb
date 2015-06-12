class SystemUserRegistrationsController < ActionController::Base
  layout "login"

  def new
    @nav_app_link = params[:app]
    #super
  end

  def create
    @nav_app_link = params[:app]
    username = params[:system_user][:username]
    password = params[:system_user][:password]
    auth_source = AuthSource.get_default_auth_source
    sys_usr = SystemUser.get_by_username_and_domain(username, auth_source.domain)
    if sys_usr
      flash[:alert] = "alert.registered_account"
    else
      auth_source = auth_source.becomes(auth_source.auth_type.constantize)
      if auth_source.authenticate("#{auth_source.domain}\\#{username}", password)
        flash[:success] = "alert.signup_completed"
        system_user = SystemUser.create(:username => username, :auth_source_id => auth_source.id)
        #if @nav_app_link
        #  redirect_to @nav_app_link
        #else
        #  redirect_to login_path
        #end
      else
        Rails.logger.info "SystemUser[username=#{username}] Registration failed. Authentication failed"
        flash[:alert] = "alert.invalid_login"
      end
    end
    render :new
  end
end
