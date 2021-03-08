class ChangeLogsController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "user_management" }
  include FormattedTimeHelper

  def index_edit_role
    authorize :change_logs, :index?

    if params[:commit].present?
      start_time = parse_date(params[:start_time])
      end_time = parse_date(params[:end_time], true)
      @system_user_change_logs = policy_scope(SystemUserChangeLog.by_action('edit_role').search_query(params[:target_system_user_name], start_time, end_time))
    end
  end

  def inactive_system_user
    authorize :change_logs, :inactive_system_user?

    if params[:commit].present?
      start_time = parse_date(params[:start_time])
      end_time = parse_date(params[:end_time], true)
      @system_user_change_logs = policy_scope(SystemUserChangeLog.by_action('inactive').search_query('', start_time, end_time))
    end
  end

  def create_system_user
    authorize :change_logs, :create_system_user?

    if params[:commit].present?
      start_time = parse_date(params[:start_time])
      end_time = parse_date(params[:end_time], true)
      @create_user_change_logs = policy_scope(SystemUserChangeLog.by_action('create').search_query('', start_time, end_time))
    end
  end

  def create_domain_licensee
    authorize :change_logs, :index_create_domain_licensee?
    @domain_licensee_change_logs = policy_scope(DomainLicenseeChangeLog.includes(:target_casinos))

    respond_to do |format|
      format.html { render file: "change_logs/index_create_domain_licensee", :layout => "domain_management", formats: [:html] }
      format.js { render template: "change_logs/index_create_domain_licensee", formats: [:js] }
    end
  end

  def index_domain_ldap
    authorize :change_logs, :index_domain_ldap?
    @domain_ldap_change_logs = DomainChangeLog.all
  end

  def index_upload_role
    authorize :change_logs, :index_upload_role?
    @upload_logs = RolePermissionsVersion.all
  end
end
