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
    auth_source = AuthSource.find_by_id(AUTH_SOURCE_ID)
    sys_usr = SystemUser.where(:username => username, :auth_source_id => auth_source.id).first

    if sys_usr
      flash[:alert] = "alert.registered_account"
    else
      auth_source = auth_source.becomes(auth_source.auth_type.constantize)
      
      if auth_source.authenticate("#{auth_source.domain}\\#{username}", password)
        profile = get_system_user_profile(username)

        if profile[:status] == false
          Rails.logger.info "SystemUser[username=#{username}] Registration failed. The account has been disabled"
          flash[:alert] = "alert.invalid_login" # TODO customize specific err msg
        elsif profile[:property_ids].blank?
          Rails.logger.info "SystemUser[username=#{username}] Registration failed. The account has no properties"
          flash[:alert] = "alert.account_no_property"
        else
          SystemUser.register!(username, auth_source.id, profile[:property_ids])
          flash[:success] = "alert.signup_completed"
        end
      else
        Rails.logger.info "SystemUser[username=#{username}] Registration failed. Authentication failed"
        flash[:alert] = "alert.invalid_login"
      end
    end
    render :new
  end

  private
  def get_system_user_profile(username)
    property_ids = Property.select(:id).pluck(:id)
    profile = Rigi::Ldap.retrieve_user_profile(username, property_ids)
    #{ :status => profile[:account_status], :property_ids => [1003, 1007] }
    { :status => profile[:account_status], :property_ids => profile[:groups] }
  end
end
