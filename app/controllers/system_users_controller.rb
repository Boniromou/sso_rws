class SystemUsersController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "user_management" }
  respond_to :html, :js
  #after_action :verify_authorized
  
  def index
    @system_users = policy_scope(SystemUser.with_active_property)
    authorize :system_users, :index?

    respond_to do |format|
      format.html { render file: "system_users/index", formats: [:html] }
      format.js { render file: "system_users/index", formats: [:js] }
    end
  end

  def show
    @system_user = SystemUser.find_by_id(params[:id])
    authorize @system_user, :show?

    respond_to do |format|
      format.html { render file: "system_users/show", formats: [:html] }
      format.js { render file: "system_users/show", formats: [:js] }
    end
  end
=begin
  def lock
    AuditLog.system_user_log("lock", current_system_user.username, sid, client_ip) do
      system_user = SystemUser.find_by_id(params[:id])
      authorize system_user
      #system_user.update_attributes({:status => 0}) if system_user
      system_user.lock
      flash[:success] = I18n.t("success.lock_user", :user_name => system_user.username)
    end
    redirect_to(system_users_path)
  end

  def unlock
    AuditLog.system_user_log("unlock", current_system_user.username, sid, client_ip) do
      system_user = SystemUser.find_by_id(params[:id])
      authorize system_user
      system_user.unlock
      flash[:success] = I18n.t("success.unlock_user", :user_name => system_user.username)
    end
    redirect_to(system_users_path)
  end
=end

  # edit roles page
  def edit_roles
    @system_user = SystemUser.find_by_id(params[:id])
    authorize @system_user, :edit_roles?
    @apps = App.all
    @current_role_ids = @system_user.role_assignments.select(:role_id).map { |role_asm| role_asm.role_id }
    @current_app_ids = @system_user.app_system_users.select(:app_id).map { |app_asm| app_asm.app_id }
    #respond_with @system_users

    respond_to do |format|
      format.html { render file: "system_users/edit_roles", formats: [:html] }
      format.js { render file: "system_users/edit_roles", formats: [:js] }
    end
  end

  def update_roles
    @system_user = SystemUser.find_by_id(params[:id])
    authorize @system_user, :update_roles?

    AuditLog.system_user_log("edit_role", current_system_user.username, sid, client_ip) do
      @system_user.update_roles(role_ids_param)
      flash[:success] = I18n.t("success.edit_role", :user_name => @system_user.username)
    end

    if request.xhr?
      show
    else
      redirect_to system_user_path(@system_user)
    end
  end

  private
  def role_ids_param
    role_ids = App.all.map do |app|
      v = params[app.name.to_sym]
      v ? v.to_i : nil
    end
    
    role_ids.compact.uniq
  end
end
