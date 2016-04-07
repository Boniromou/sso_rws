class ChangeLogsController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "user_management" }

  def index
    authorize :system_user_change_logs, :index?

    if params[:commit].present?
      @system_user_change_logs = policy_scope(SystemUserChangeLog.search_query(params[:target_system_user_name], params[:start_time], params[:end_time]))
    end
  end

  def index_edit_role
    # authorize :change_logs, :index_edit_role?
    if params[:commit].present?
      @system_user_change_logs = policy_scope(ChangeLog.search_edit_role(params))
    end
  end
end