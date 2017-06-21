class SystemUserSessionsController < Devise::SessionsController
  layout "login"

  def new
    redirect_to "#{root_url}app_login?app_name=#{APP_NAME}"
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
