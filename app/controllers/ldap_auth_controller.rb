class LdapAuthController < ApplicationController
  layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
    check_login_type!(['ldap', 'openldap', 'usdm'])
    @message_id = SecureRandom.hex
    session[:message_id] = @message_id
    @app_name = params[:app_name]
  end

  def create
    check_message_id
    auth_source = AuthSource.find_by_token(get_client_ip)
    check_domain_type(auth_source.type)
    system_user = auth_source.authorize!(params[:system_user][:username], params[:system_user][:password], params[:app_name], auth_info['casino_id'], auth_info['permission'])
    Rails.logger.info 'Authorize successfully.'
    write_authorize_cookie({error_code: 'OK', error_message: 'Authorize successfully.', authorized_by: params[:system_user][:username], authorized_at: Time.now})
    redirect_to auth_info['callback_url']
  rescue Rigi::InvalidLogin, Rigi::InvalidDomainType => e
    @app_name = params[:app_name]
    flash[:alert] = I18n.t(e.error_message)
    render :template => "ldap_auth/new"
  rescue Rigi::InvalidAuthorize, Rigi::DuplicateAuthorize => e
    Rails.logger.error "Authorize failed: #{e.error_message}"
    write_authorize_cookie({error_code: e.class.name.demodulize, error_message: e.error_message})
    redirect_to auth_info['callback_url']
  end

  protected
  def check_message_id
    message_id = session[:message_id]
    session.delete(:message_id)
    raise Rigi::DuplicateAuthorize.new('Duplicate authorization.') if message_id != params[:message_id]
  end

  def check_domain_type(token_type)
    domain = Domain.find_by_name(params[:system_user][:username].split('@')[1])
    if !domain || domain.user_type != token_type
      domain_type = domain.user_type if domain
      Rails.logger.error "Invalid domain type: token type [#{token_type}], domain type [#{domain_type}]"
      raise Rigi::InvalidDomainType.new('invalid_domain')
    end
  end
end
