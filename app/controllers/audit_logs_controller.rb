class AuditLogsController < ApplicationController
  layout proc { |controller|
    respond_to do |format|
      format.html { 'audit_log' }
      format.js { false }
    end
  }

#  rescue_from Pundit::NotAuthorizedError, :with => :handle_activated_user_unauthorize
  include Rigi::Searchable

  def search
    authorize :audit_log, :search?

    (request.post? && params[:commit] == I18n.t("general.search")) ? handle_search_with_result : handle_search
  end

  private
  
  def handle_search
    @default_start_time = Date.parse(Time.now.to_s) - (SEARCH_DAY_RANGE - 1).days
    @default_end_time = Date.parse(Time.now.to_s)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def handle_search_with_result
    start_time, end_time, remark = search_time_range_limitation(params[:start_time], params[:end_time], SEARCH_RANGE_FOR_AUDIT_LOG)
    if start_time.nil? && end_time.nil?
      @search_time_range_error = I18n.t("auditlog.search_range_error", :config_value => SEARCH_RANGE_FOR_AUDIT_LOG)
    else
      @search_time_range_remark = I18n.t("auditlog.search_range_remark", :config_value => SEARCH_RANGE_FOR_AUDIT_LOG) if remark
      action_by = params[:action_by] unless params[:action_by].blank?
      action_type = params[:action_type] unless params[:action_type].blank?
      audit_target = params[:target_name] unless params[:target_name].blank? || params[:target_name] == "all"
      action = params[:action_list] unless params[:action_list].blank? || params[:action_list] == "all"
      @audit_logs = AuditLog.search_query(audit_target, action, action_type, action_by, start_time, end_time)
    end

    respond_to do |format|
      format.html { render partial: "audit_logs/search_result", formats: [:html] }
      format.js { render partial: "audit_logs/search_result", formats: [:js] }
    end
  end
end
