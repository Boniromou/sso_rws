class SystemUsersController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "administration" }
  respond_to :html, :js
  
  def index
    @system_users = SystemUser.all
    session[:previous_action] = "index"
    respond_to do |format|
      format.html { render file: "system_users/index", formats: [:html] }
      format.js { render file: "system_users/index", formats: [:js] }
    end
  end

  def show
    @system_user = SystemUser.find_by_id(params[:id])
    session[:previous_action] = "show"
    respond_to do |format|
      format.html { render file: "system_users/show", formats: [:html] }
      format.js { render file: "system_users/show", formats: [:js] }
    end
  end

  def lock
    AuditLog.system_user_log("lock", current_system_user.username, sid, client_ip) {
      system_user = SystemUser.find_by_id(params[:id])
      system_user.update_attributes({:status => 0}) if system_user
    }

    redirect_to :back
    #refresh_last_page
  end

  def unlock
    AuditLog.system_user_log("unlock", current_system_user.username, sid, client_ip) {
      system_user = SystemUser.find_by_id(params[:id])
      system_user.update_attributes({:status => 1}) if system_user
    }
    redirect_to :back
    #refresh_last_page
  end

  # edit roles page
  def edit_roles
    @system_user = SystemUser.find_by_id(params[:id])
    @roles = Role.all
    #respond_with @system_users
    respond_to do |format|
      format.html { render file: "system_users/edit_roles", formats: [:html] }
      format.js { render file: "system_users/edit_roles", formats: [:js] }
    end
  end

  def update_roles
    AuditLog.system_user_log("edit_role", current_system_user.username, sid, client_ip) {
      system_user = SystemUser.find_by_id(params[:id])
      if params[:commit] == I18n.t("general.confirm")
        system_user.update_roles(params[:roles])
        flash[:success] = "flash_message.success"
      end
    }
    @system_user = SystemUser.find_by_id(params[:id])
    if request.xhr?
      show
    else
      redirect_to system_user_path(@system_user)
    end
  end

  private
  def refresh_last_page
    #send session[:previous_action]
     render :action => session[:previous_action]
  end
end
