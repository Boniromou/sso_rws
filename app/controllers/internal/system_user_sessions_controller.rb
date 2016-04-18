class Internal::SystemUserSessionsController < ApplicationController
  skip_before_filter :set_locale, :authenticate_system_user!, :check_activation_status, :verify_request_scope
  respond_to :json

  def create
    username = params[:system_user][:username].downcase
    password = params[:system_user][:password]
    app_name = params[:app_name]
    response_body = {}
    response_status = :ok

    begin
      response_body[:system_user] = Rigi::Login.authenticate!(username, password, app_name)
      response_body[:message] = "success"
      response_body[:success] = true
    rescue Rigi::InvalidLogin => e
      response_body[:message] = e.error_message
      response_body[:success] = false
      response_status = :unauthorized
    rescue Exception => e
      response_body[:message] = e.message
      response_body[:success] = false
      response_status = :internal_server_error
    end

    respond_to do |format|
      format.json { render :json => response_body, :status => response_status }
    end
  end
end
