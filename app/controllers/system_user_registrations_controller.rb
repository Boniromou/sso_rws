class SystemUserRegistrationsController < ActionController::Base
  layout "login"

  def new
    @nav_app_link = params[:app]
    #super
  end

  def create
    begin
      [:success, :alert].each do |key|
        flash.delete(key)
      end     
      @nav_app_link = params[:app]
      username_with_domain = params[:system_user][:username].downcase
      login = Rigi::Login.extract_login_name(username_with_domain)
      raise Rigi::InvalidLogin if login.nil?

      username = login[:username]
      domain = login[:domain]
      password = params[:system_user][:password]
      SystemUser.validate_account!(username, domain)

      auth_source = AuthSource.first
      auth_source = auth_source.becomes(auth_source.auth_type.constantize)
      if auth_source.authenticate(username_with_domain, password)
        SystemUser.register_account!(username, domain)
        flash[:success] = "alert.signup_completed"     
      else 
        raise Rigi::InvalidLogin
      end
    rescue Rigi::InvalidLogin, Rigi::InvalidUsername, Rigi::InvalidDomain
      Rails.logger.error "SystemUser[username=#{username_with_domain}] illegal login name format"
      flash[:alert] = "alert.invalid_login"
    rescue Rigi::RegisteredAccount
      Rails.logger.error "SystemUser[username=#{username_with_domain}] register failed: {The account has been registered}"
      flash[:alert] = "alert.registered_account"
    rescue Rigi::AccountNotInLdap
      Rails.logger.error "SystemUser[username=#{username_with_domain}] register failed: {Account is not in ldap server}"
      flash[:alert] = "alert.account_not_in_ldap"
    rescue Rigi::AccountNoCasino
      Rails.logger.error "SystemUser[username=#{username_with_domain}] register failed: {Account no casino}"
      flash[:alert] = "alert.account_no_casino"
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
