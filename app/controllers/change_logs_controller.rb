class ChangeLogsController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "user_management" }

  def index
    authorize :system_user_change_logs, :index?

    if params[:commit].present?
      @system_user_change_logs = policy_scope(SystemUserChangeLog.search_query(params[:target_system_user_name], params[:start_time], params[:end_time]))
    end
  end

  def create_system_user
    authorize :change_logs, :create_system_user?

    @create_user_change_logs = policy_scope(SystemUserChangeLog.by_action('create').search_query('', params[:start_time], params[:end_time])) if params[:commit].present?

  end

  def index_create_domain_casino
    authorize :change_logs, :index_create_domain_casino?
    @create_domain_casino_change_logs = policy_scope(DomainCasinoChangeLog)
  end
end