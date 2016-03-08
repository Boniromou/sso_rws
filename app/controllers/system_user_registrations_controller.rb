class SystemUserRegistrationsController < ActionController::Base
  layout "login"

  def new
    @nav_app_link = params[:app]
    #super
  end

  def create
    @nav_app_link = params[:app]
    username_with_domain = params[:system_user][:username].downcase
    login = Rigi::Login.extract_login_name(username_with_domain)

    if login.nil?
      Rails.logger.error "SystemUser[username=#{username_with_domain}] illegal login name format"
      flash[:alert] = "alert.invalid_login"
    else
      username = login[:username]
      domain = login[:domain]
      password = params[:system_user][:password]

      domain_obj = Domain.where(:name => domain).first
      if !domain_obj
        Rails.logger.error "SystemUser[username=#{username_with_domain}] illegal domain"
        flash[:alert] = "alert.invalid_login"
      else
        auth_source = AuthSource.first
        sys_usr = SystemUser.where(:username => username, :auth_source_id => auth_source.id, :domain_id => domain_obj.id).first

        if sys_usr
          flash[:alert] = "alert.registered_account"
        else
          auth_source = auth_source.becomes(auth_source.auth_type.constantize)

          if auth_source.authenticate(username_with_domain, password)
            #profile = get_system_user_profile(username)
            casino_ids = Casino.select(:id).pluck(:id)
            profile = auth_source.retrieve_user_profile(username, domain, casino_ids)

            if profile[:status] == false
              Rails.logger.info "SystemUser[username=#{username}] Registration failed. The account has been disabled"
              flash[:alert] = "alert.invalid_login" # TODO customize specific err msg
            elsif profile[:casino_ids].blank?
              Rails.logger.info "SystemUser[username=#{username}] Registration failed. The account has no casinos"
              flash[:alert] = "alert.account_no_casino"
            else
              SystemUser.register!(username, domain, auth_source.id, profile[:casino_ids])
              flash[:success] = "alert.signup_completed"
            end
          else
            Rails.logger.info "SystemUser[username=#{username}] Registration failed. Authentication failed"
            flash[:alert] = "alert.invalid_login"
          end
        end
      end
    end

    render :new
  end
=begin
  private
  def get_system_user_profile(auth_source, username)
    property_ids = Property.select(:id).pluck(:id)
    profile = Rigi::Ldap.retrieve_user_profile(username, property_ids)
    #{ :status => profile[:account_status], :property_ids => [1003, 1007] }
    { :status => profile[:account_status], :property_ids => profile[:groups] }
  end
=end
end
