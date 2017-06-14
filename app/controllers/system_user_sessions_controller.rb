class SystemUserSessionsController < Devise::SessionsController
  layout "login"

  def sso_login
    redirect_to "#{root_url}/new?app_name=user_management"
  end

  def new
    @app_name = params[:app_name]
    raise "app not found" unless @app_name
    auth_source = AuthSource.find_by_token(get_client_ip)
    if auth_source.nil?
      error_info = { message: I18n.t("alert.bad_gateway_message"),
                      status: I18n.t("alert.bad_gateway_status"),
                      note: I18n.t("alert.unkown_token")}
      redirect_to error_warning_path(error_info)
    else
      redirect_to "#{auth_source.get_url}?app_name=#{@app_name}"
    end
  end

  def error_warning
    @error_info = params
    render layout: false
  end

  def create
    super
  end

  def destroy
    super
  end
end
