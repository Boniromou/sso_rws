class AuditLogsController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "audit_log" }

  def search
    if request.post? && params[:commit] == I18n.t("general.search")
      search_params = {}
      start_time = parse_date(params[:start_time]) unless params[:start_time].blank?
      end_time = parse_date(params[:end_time], true) unless params[:end_time].blank?
      action_by = params[:action_by] unless params[:action_by].blank?
      search_params[:action_type] = params[:action_type] unless params[:action_type].blank?
      search_params[:audit_target] = params[:target_name] unless params[:target_name].blank? || params[:target_name] == "all"
      search_params[:action] = params[:action_list] unless params[:action_list].blank? || params[:action_list] == "all"
      @audit_logs = get_audit_logs(start_time, end_time, action_by, search_params)
      
      respond_to do |format|
        format.html { render partial: "audit_logs/search_result", formats: [:html] }
        format.js { render partial: "audit_logs/search_result", formats: [:js] }
      end
    else
      respond_to do |format|
        format.html
        format.js
      end
    end
  end
  
  def action_list
    if params[:target] == "all"
      actions = ["all"]
    else
      actions = ["all"] + AuditLog.actions_for(params[:target])
    end
    @action_list = []
    actions.each { |a| @action_list << [a.titleize, a] }
    respond_to do |format|
      format.js
    end
  end
  
  private
  def get_audit_logs(start_time, end_time, action_by, search_params)
    if start_time && end_time
      AuditLog.where(search_params).where("action_by LIKE ?", "%#{action_by}%").where("action_at > ? AND action_at < ?", start_time, end_time)
    else
      if start_time
        AuditLog.where(search_params).where("action_by LIKE ?", "%#{action_by}%").where("action_at > ?", start_time)
      elsif end_time
        AuditLog.where(search_params).where("action_by LIKE ?", "%#{action_by}%").where("action_at < ?", end_time)
      else
        AuditLog.where(search_params).where("action_by LIKE ?", "%#{action_by}%")
      end
    end
  end
  
  def parse_date(date_str, is_end_time=false)
    if is_end_time
      Time.strptime(date_str + " 23:59:59", "%Y-%m-%d %H:%M:%S")
    else
      Time.strptime(date_str, "%Y-%m-%d")
    end
  end
end
