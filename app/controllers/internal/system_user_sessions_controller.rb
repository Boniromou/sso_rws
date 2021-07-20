class Internal::SystemUserSessionsController < ApplicationController
  skip_before_filter :set_locale, :authenticate_system_user!, :check_activation_status, :verify_request_scope

  def login
    @app_name = params[:app_name]
    raise "app not found" unless @app_name
    auth_source = AuthSource.find_by_token(get_client_ip)
    if auth_source.nil?
      @error_info = { message: I18n.t("alert.bad_gateway_message"),
                      status: I18n.t("alert.bad_gateway_status"),
                      note: I18n.t("alert.unknown_token")}
      render layout: false, template: 'system_user_sessions/error_warning'
    else
      redirect_to auth_source.get_url(@app_name)
    end
  end

  def logout
    update_sign_out
    auth_source = AuthSource.find_by_token(get_client_ip)
    if auth_source.type.downcase == 'gapi'
      @app_name = params[:app_name]
      @g_clien_id = auth_source.auth_source_detail['data']['client_id']
      render layout: 'login', :template => "system_user_sessions/google_logout"
    else
      redirect_to "#{URL_BASE}/app_login?app_name=#{params[:app_name]}"
    end
  end

  def ssrs_login
    redirect_to "#{URL_BASE}/app_login?app_name=#{SSRS_APP_NAME}"
  end

  protected
  def update_sign_out
    return if params[:auth_token].blank?
    user_info = JWT.decode(params[:auth_token], 'test_key', true)[0]
    Rails.logger.info "token info: #{user_info}"
    LoginHistory.update_sign_out(user_info['id'], user_info['session_token'])
  rescue StandardError => e
    Rails.logger.error("logout decode auth token error: #{e.message} #{e.backtrace}")
  end
end
