class GapiController < ApplicationController
  layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
    check_login_type!('gapi')
    @app_name = params[:app_name]
    auth_source = AuthSource.find_by_token(get_client_ip)
    @g_clien_id = auth_source.auth_source_detail['data']['client_id']
    render :template => "system_user_sessions/google_new"
  end

  def login
    auth_source = AuthSource.find_by_token(get_client_ip)
    casino_id = auth_source.auth_source_detail['data']['casino_id']
    verify_id_token(auth_source.auth_source_detail['data'])
    system_user = auth_source.authenticate!(params[:username], params[:app_name], [casino_id])
    write_authenticate(system_user, params[:app_name])
    callback_url = App.find_by_name(params[:app_name]).callback_url
    render :json => {error_code: 'OK', error_msg: 'Request is now completed', callback_url: callback_url}
   rescue Rigi::InvalidLogin => e
    @app_name = params[:app_name]
    render :json => {error_code: 'InvalidLogin', error_msg: I18n.t(e.error_message)}
  end

  protected

  def verify_id_token(data)
    public_key = OpenSSL::PKey::RSA.new(data['public_key'])
    token_info = JWT.decode(params[:id_token], public_key, true, { algorithm: 'RS256' })[0]
    Rails.logger.info("Verify google id_token: #{token_info}")
    if token_info['aud'] != data['client_id'] || token_info['email'] != params[:username]
      Rails.logger.info('Verify google id_token failed.')
      raise Rigi::InvalidLogin.new('alert.invalid_google_token')
    end
  rescue StandardError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    raise Rigi::InvalidLogin.new('alert.invalid_google_token')
  end
end
