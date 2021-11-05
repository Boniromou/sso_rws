class LdapController < ApplicationController
  layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
    check_login_type!(['ldap', 'openldap', 'usdm'])
    @login_type = AuthSource.find_by_token(get_client_ip).type.downcase
    @app_name = params[:app_name]
    render :template => "system_user_sessions/ldap_new"
  end

  def login
    auth_source = AuthSource.find_by_token(get_client_ip)
    check_domain_type(auth_source.type)
    session_token = SecureRandom.uuid
    system_user = auth_source.login!(params[:system_user][:username], params[:system_user][:password], params[:app_name], session_token)
    write_authenticate(system_user, params[:app_name], session_token)
    redirect_to App.find_by_name(params[:app_name]).callback_url
  rescue Rigi::InvalidLogin, Rigi::InvalidDomainType, Rigi::RemoteError => e
    @app_name = params[:app_name]
    @login_type = auth_source.type.downcase
    flash[:alert] = I18n.t(e.error_message)
    render :template => "system_user_sessions/ldap_new"
  end

  protected
  def check_domain_type(token_type)
    domain = Domain.find_by_name(params[:system_user][:username].split('@')[1])
    if !domain || domain.user_type != token_type
      domain_type = domain.user_type if domain
      Rails.logger.error "Invalid domain type: token type [#{token_type}], domain type [#{domain_type}]"
      raise Rigi::InvalidDomainType.new('invalid_domain')
    end
  end
end
