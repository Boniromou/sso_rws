class DashboardController < ApplicationController
  def home
    respond_to do |format|
      format.html { render file: "dashboard/home", :layout => "home", formats: [:html] }
      format.js { render template: "dashboard/home", formats: [:js] }
    end
  end

  def user_management
    @system_users = SystemUser.inactived
    @unshow_operation = true
    authorize :dashboard, :user_management?
    response_client
  end

  def audit_log
    authorize :dashboard, :audit_log?
    respond_to do |format|
      format.html { render file: "dashboard/audit_log", :layout => "audit_log", formats: [:html] }
      format.js { render template: "dashboard/management", formats: [:js] }
    end
  end

  def role_management
    #authorize :dashboard, :role_management?
    response_client
  end

  def domain_management
    #authorize :dashboard, :domain_management?
    #authorize :domain, :list?
    #authorize :domain, :create_domain_casino
    response_client
  end

  protected
  def dashboard_layout
    request.xhr? ? false : params[:action]
  end

  private
  def response_client
    respond_to do |format|
      format.html { render file: "dashboard/#{action_name}", layout: "management", formats: [:html] }
      format.js { render template: "dashboard/management", formats: [:js] }
    end
  end
end
