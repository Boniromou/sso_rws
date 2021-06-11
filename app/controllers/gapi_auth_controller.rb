class GapiAuthController < ApplicationController
  layout "login"
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
    check_login_type!('gapi')
    @app_name = params[:app_name]
    auth_source = AuthSource.find_by_token(get_client_ip)
    @g_clien_id = auth_source.auth_source_detail['data']['client_id']
  end

  def create
    auth_source = AuthSource.find_by_token(get_client_ip)
    system_user = auth_source.authorize!(params[:username], params[:app_name], auth_info['casino_id'], auth_info['permission'])
    Rails.logger.info 'Authorize successfully.'
    write_authorize_cookie({error_code: 'OK', error_message: 'Authorize successfully.', authorized_by: params[:username], authorized_at: Time.now})
    render :json => {error_code: 'OK', error_msg: 'Request is now completed', callback_url: auth_info['callback_url']}
  rescue Rigi::InvalidLogin => e
    @app_name = params[:app_name]
    render :json => {error_code: 'InvalidLogin', error_msg: I18n.t(e.error_message)}
  rescue Rigi::InvalidAuthorize, Rigi::DuplicateAuthorize => e
    Rails.logger.error "Authorize failed: #{e.error_message}"
    write_authorize_cookie({error_code: e.class.name.demodulize, error_message: e.error_message})
    render :json => {error_code: 'InvalidAuthorize', error_msg: 'Authorize failed.', callback_url: auth_info['callback_url']}
  end
end
