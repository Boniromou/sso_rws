class Internal::SystemUsersController < ApplicationController
  skip_before_filter :set_locale, :authenticate_system_user!, :check_activation_status, :verify_request_scope
  rescue_from Rigi::InvalidParameter, :with => :handle_invalid_parameter

  def second_authorize
    check_auth_info!
    auth_source = AuthSource.find_by_token(get_client_ip)
    raise Rigi::InvalidParameter if auth_source.nil?
    redirect_to auth_source.get_auth_url(auth_info['app_name'])
  end

  private
  def check_auth_info!
    raise Rigi::InvalidParameter unless cookies[:second_auth_info]
    raise Rigi::InvalidParameter if (['app_name', 'casino_id', 'permission', 'callback_url'] - auth_info.keys).present?
  end

  def handle_invalid_parameter
    write_authorize_cookie({error_code: 'InvalidParameter', error_message: 'Authorize failed, invalid parameters.'})
    raise "callback excaption" unless auth_info['callback_url']
    redirect_to auth_info['callback_url']
  end
end
