class SystemUserRegistrationsController < ApplicationController
  layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status
  rescue_from Exception, :with => :handle_fatal_error

  def new
    @nav_app_link = params[:app]
    #super
  end

  def create
    # begin
    #   [:success, :alert].each do |key|
    #     flash.delete(key)
    #   end
    #   @nav_app_link = params[:app]
    #   username_with_domain = params[:system_user][:username].downcase
    #   login = Rigi::Login.extract_login_name(username_with_domain)
    #   raise Rigi::InvalidLogin.new("alert.invalid_login") if login.nil?

    #   username = login[:username]
    #   domain = login[:domain]
    #   password = params[:system_user][:password]

    #   auth_source = SystemUser.validate_account!(username, domain)
    #   auth_source = auth_source.becomes(auth_source.auth_type.constantize)
    #   if auth_source.authenticate(username_with_domain, password)
    #     SystemUser.register_account!(username, domain)
    #     flash.now[:success] = "alert.signup_completed"
    #   else
    #     raise Rigi::InvalidLogin.new("alert.invalid_login")
    #   end
    # rescue Rigi::InvalidLogin, Rigi::InvalidUsername, Rigi::InvalidDomain
    #   Rails.logger.error "SystemUser[username=#{username_with_domain}] illegal login name format"
    #   flash.now[:alert] = "alert.invalid_login"
    # rescue Rigi::InvalidAuthSource => e
    #   Rails.logger.error "SystemUser[username=#{username_with_domain}] invalid domain - auth_source mapping"
    #   flash.now[:alert] = e.error_message
    # rescue Rigi::RegisteredAccount
    #   Rails.logger.error "SystemUser[username=#{username_with_domain}] register failed: {The account has been registered}"
    #   flash.now[:alert] = "alert.registered_account"
    # rescue Rigi::AccountNotInLdap
    #   Rails.logger.error "SystemUser[username=#{username_with_domain}] register failed: {Account is not in ldap server}"
    #   flash.now[:alert] = "alert.account_not_in_ldap"
    # rescue Rigi::AccountNoCasino
    #   Rails.logger.error "SystemUser[username=#{username_with_domain}] register failed: {Account no casino}"
    #   flash.now[:alert] = "alert.account_no_casino"
    # end

    # render :new
  end

  def edit
    @nav_app_link = params[:app]
    @app_name = params[:app_name]
  end

  def update
    @nav_app_link = params[:app]
    @app_name = params[:app_name]
    begin
      auth_source = find_auth_source
      check_new_password
      system_user = auth_source.change_password!(params[:system_user][:username], params[:system_user][:old_password], params[:system_user][:new_password])
      flash.now[:success] = I18n.t("success.reset_password")
    rescue Rigi::InvalidLogin, Rigi::InvalidDomain, Rigi::RemoteError => e
      Rails.logger.error "SystemUser[username=#{params[:system_user][:username]}] reset password failed: #{e.error_message}"
      flash.now[:alert] = e.error_message
    end
    render :edit
  end

  protected
  def check_new_password
    raise Rigi::InvalidLogin.new("password_page.new_password_tooltip") if params[:system_user][:new_password].blank?
    raise Rigi::InvalidLogin.new("password_page.confirm_password_fail") if params[:system_user][:new_password] != params[:system_user][:password_confirmation]
  end

  def find_auth_source
    domain = Domain.find_by_name(params[:system_user][:username].split('@')[1])
    raise Rigi::InvalidDomain.new('alert.invalid_domain') if !domain
    raise Rigi::InvalidDomain.new('alert.cannot_change_password') if domain.user_type != 'Usdm'
    domain.user_type.constantize.new
  end

  def handle_fatal_error(e)
    @from = params[:from]
    Rails.logger.error "#{e.message}"
    Rails.logger.error "#{e.backtrace.inspect}"

    respond_to do |format|
      format.html { render partial: "shared/error500", formats: [:html], layout: "error_page", status: :internal_server_error }
      format.js { render partial: "shared/error500", formats: [:js], status: :internal_server_error }
    end
    return
  end
end
