class LoginHistoriesController < ApplicationController
	layout proc {|controller| controller.request.xhr? ? false: "user_management" }
  respond_to :html, :js

  def index
    authorize :login_history, :list?

    if params[:commit].present?
      handle_search_with_result
    else
      @default_start_time = Date.today - (SEARCH_RANGE_FOR_LOGIN_HISTORY - 1).days
      @default_end_time = Date.today
      @apps = App.all
    end
  end

  private

  def handle_search_with_result
    start_time, end_time, remark = SearchTimeLimitation::search_time_range_limitation(params[:start_time], params[:end_time], SEARCH_RANGE_FOR_LOGIN_HISTORY)
    if start_time.nil? && end_time.nil?
      @search_error = I18n.t("login_history.search_range_error", :config_value => SEARCH_RANGE_FOR_LOGIN_HISTORY)
    else
      if remark
        @search_time_range_remark = I18n.t("login_history.search_range_remark", :config_value => SEARCH_RANGE_FOR_LOGIN_HISTORY)
        @default_start_time = start_time.localtime.strftime("%Y-%m-%d")
        @default_end_time = (end_time.localtime - 1.days).strftime("%Y-%m-%d")
      end
      if params[:username].present?
	      system_user = SystemUser.find_by_username_with_domain(params[:username])
	      if system_user.present?
		      system_user_id = system_user.id
		      domain_id = system_user.domain_id
        else
          @search_error = I18n.t("login_history.search_system_user_error")
		    end
	    end

	    if @search_error.blank?
	      app_id = params[:app_id] unless params[:app_id].blank? || params[:app_id] == "all"
		    @login_histories = policy_scope(LoginHistory.search_query(system_user_id, domain_id, app_id, start_time, end_time))
		  end
    end
  end
end