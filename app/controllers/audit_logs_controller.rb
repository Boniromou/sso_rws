class AuditLogsController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "audit_log" }
  include SearchTimeLimitation

  def search
    (request.post? && params[:commit] == I18n.t("general.search")) ? handle_search_with_result : handle_search

=begin
    if request.post? && params[:commit] == I18n.t("general.search")
      start_time = parse_search_time(params[:start_time]) unless params[:start_time].blank?
      end_time = parse_search_time(params[:end_time], true) unless params[:end_time].blank?
      action_by = params[:action_by] unless params[:action_by].blank?
      action_type = params[:action_type] unless params[:action_type].blank?
      audit_target = params[:target_name] unless params[:target_name].blank? || params[:target_name] == "all"
      action = params[:action_list] unless params[:action_list].blank? || params[:action_list] == "all"
      @audit_logs = AuditLog.search_query(audit_target, action, action_type, action_by, start_time, end_time)

      respond_to do |format|
        format.html { render partial: "audit_logs/search_result", formats: [:html] }
        format.js { render partial: "audit_logs/search_result", formats: [:js] }
      end
    else
      @action_lists = AuditLog::ACTION_MENU
      respond_to do |format|
        format.html
        format.js
      end
    end
=end
  end

  private

  def handle_search
    @action_lists = AuditLog::ACTION_MENU
      respond_to do |format|
      format.html
      format.js
    end
  end

  def handle_search_with_result
    start_time, end_time, remark = search_time_range_limitation(params[:start_time], params[:end_time], SEARCH_RANGE_FOR_AUDIT_LOG)
    if start_time.nil? && end_time.nil?
      @search_time_range_error = I18n.t("audit_log.search_range_error", :config_value => SEARCH_RANGE_FOR_AUDIT_LOG)
      authorize AuditLog.new
    else
      @search_time_range_remark = I18n.t("audit_log.search_range_remark", :config_value => SEARCH_RANGE_FOR_AUDIT_LOG) if remark
      action_by = params[:action_by] unless params[:action_by].blank?
      action_type = params[:action_type] unless params[:action_type].blank?
      audit_target = params[:target_name] unless params[:target_name].blank? || params[:target_name] == "all"
      action = params[:action_list] unless params[:action_list].blank? || params[:action_list] == "all"
      @audit_logs = AuditLog.search_query(audit_target, action, action_type, action_by, start_time, end_time)
      authorize @audit_logs
    end

    respond_to do |format|
      format.html { render partial: "audit_logs/search_result", formats: [:html] }
      format.js { render partial: "audit_logs/search_result", formats: [:js] }
     end
   end
end
