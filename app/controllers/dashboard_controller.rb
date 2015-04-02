class DashboardController < ApplicationController
  def home
    respond_to do |format|
      format.html { render file: "dashboard/home", :layout => "home", formats: [:html] }
      format.js { render template: "dashboard/home", formats: [:js] }
    end
  end

  def user_management
    authorize :dashboard, :user_management?
    respond_to do |format|
      format.html { render file: "dashboard/user_management", :layout => "user_management", formats: [:html] }
      format.js { render template: "dashboard/user_management", formats: [:js] }
    end
  end

  def audit_log
    authorize :dashboard, :audit_log?
    respond_to do |format|
      format.html { render file: "dashboard/audit_log", :layout => "audit_log", formats: [:html] }
      format.js { render template: "dashboard/audit_log", formats: [:js] }
    end
  end

  def role_management
    #authorize :dashboard, :role_management?
    respond_to do |format|
      format.html { render file: "dashboard/role_management", :layout => "role_management", formats: [:html] }
      format.js { render template: "dashboard/role_management", formats: [:js] }
    end
  end

  protected
  def dashboard_layout
    request.xhr? ? false : params[:action]
  end
end
