class SystemUserSessionsController < Devise::SessionsController
  layout "login"

  def sso_login
    redirect_to "#{root_url}/new?app_name=user_management"
  end

  def new
    @app_name = params[:app_name]
    raise "app not found" unless @app_name
    token = request.remote_ip
    auth_source = AuthSource.find_by_token(token)
    if auth_source.nil?
      @error_message = 'unkown type'
    else
      redirect_to "#{auth_source.get_url}?app_name=#{@app_name}"
    end
  end

  def create
    super
  end

  def destroy
    super
  end
end
