class RolesController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "role_management" }
  respond_to :html, :js

  def index
    authorize :role, :index?
    apps = App.all
    roles = policy_scope(Role)

    @roles_by_apps = apps.map do |app|
      ros = roles.find_all { |role| role.app_id == app.id }
      next if ros.blank?
      {:app => app, :roles => ros }
    end.compact

    respond_to do |format|
      format.html { render file: "roles/#{action_name}", layout: "role_management", formats: [:html] }
      format.js { render template: "roles/#{action_name}", formats: [:js] }
    end
  end

  def show
    @role = Role.includes(:role_permissions => :permission).find_by_id(params[:id])
    @permissions_by_role = Role.target_permissions(params[:id])
    #authorize Permission.new
    authorize :permission, :show?

    app_id = @role.app_id
    @app = App.find_by_id(app_id)
    @permissions_by_app = @app.permissions_with_groups
  end

  def export
    authorize :role, :index?
    roles = policy_scope(Role.includes(:permissions))
    respond_to do |format|
      format.xls do
        current_time = Time.now.strftime("%Y-%m-%d %H-%M-%S")
        send_data Role.get_export_role_pessmission(roles), :type => :xls, :filename => I18n.t("role.export_file_name", :current_time => current_time)
      end
    end
  end
end
