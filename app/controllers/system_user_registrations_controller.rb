class SystemUserRegistrationsController < Devise::RegistrationsController
  layout "login"

  def new
    super
  end

  def create
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
        SystemUser.create(:username => username, :auth_source_id => auth_source.id)
      else
        Rails.logger.info "SystemUser[username=#{username}] Registration failed. Authentication failed"
        flash[:alert] = "alert.invalid_login"
      end
    end
    render :new
  end

  def update
    super
  end

  def after_sign_up_path_for(resource)
    #new_sign_in_path(resource)
    signed_in_root_path(resource)
  end

  def after_update_path_for(resource)
    #new_sign_in_path(resource)
    signed_in_root_path(resource)
  end
end
