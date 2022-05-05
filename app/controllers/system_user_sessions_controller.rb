class SystemUserSessionsController < Devise::SessionsController
  layout "login"

  def new
    redirect_to "#{URL_BASE}/app_login?app_name=#{APP_NAME}"
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

  def after_sign_out_path_for(resource)
    auth_token = cookies[:user_management_token_info]
    cookies.delete(:user_management_token_info, domain: :all)
    "#{URL_BASE}/app_logout?app_name=#{APP_NAME}&auth_token=#{auth_token}"
  end
end
