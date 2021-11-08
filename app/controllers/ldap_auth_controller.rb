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
    auth_source = find_auth_source
    system_user = auth_source.authorize!(params[:system_user][:username], params[:system_user][:password], params[:app_name], auth_info['casino_id'], auth_info['permission'])
    Rails.logger.info 'Authorize successfully.'
    write_authorize_cookie({error_code: 'OK', error_message: 'Authorize successfully.', authorized_by: params[:system_user][:username], authorized_at: Time.now})
    redirect_to auth_info['callback_url']
  rescue Rigi::InvalidLogin, Rigi::InvalidDomain => e
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

  def find_auth_source
    domain = Domain.find_by_name(params[:system_user][:username].split('@')[1])
    raise Rigi::InvalidDomain.new('alert.invalid_domain') if !domain
    domain.user_type.constantize.new
  end
end
