class Internal::SystemUserSessionsController < ApplicationController
  skip_before_filter :set_locale, :authenticate_system_user!, :check_activation_status, :verify_request_scope

  def login
    @app_name = params[:app_name]
    raise "app not found" unless @app_name
    auth_source = AuthSource.find_by_token(get_client_ip)
    if auth_source.nil?
      @error_info = { message: I18n.t("alert.bad_gateway_message"),
                      status: I18n.t("alert.bad_gateway_status"),
                      note: I18n.t("alert.unkown_token")}
      render layout: false, template: 'system_user_sessions/error_warning'
    else
      redirect_to "#{auth_source.get_url}?app_name=#{@app_name}"
    end
  end
end
