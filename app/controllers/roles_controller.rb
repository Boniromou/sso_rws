class RolesController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "role_management" }
  respond_to :html, :js

  def index
#    @roles = Role.all
    @apps = App.all
    authorize Role.new
  end

  def show
    @role = Role.find_by_id(params[:id])
    @permissions_by_role = Role.target_permissions(params[:id])
    authorize Permission.new

    app_id = @role.app_id   
    @app = App.find_by_id(app_id)
    @permissions_by_app = App.permissions(app_id)
  end
end
