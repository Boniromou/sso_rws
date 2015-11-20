require 'admin_portal_error'

class ApplicationController < ActionController::Base
  layout false
  include Pundit
  include Rigi::PunditHelper::Controller
  protect_from_forgery
  before_filter :set_locale, :authenticate_system_user!, :check_activation_status
  respond_to :html, :js

  #rescue_from ::ActiveRecord::RecordInvalid, :with => :handle_invalid_error
  #rescue_from ::ActiveRecord::StaleObjectError, :with => :handle_unsync_error
  rescue_from Exception, :with => :handle_fatal_error
  rescue_from Pundit::NotAuthorizedError, :with => :handle_unauthorize

  def set_locale
    I18n.locale = params[:locale] && I18n.available_locales.include?(params[:locale].to_sym) ? params[:locale] : I18n.default_locale
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(SystemUser)
      Rails.logger.info "A SystemUser logged in. Session=#{session.inspect}"
      #Rails.logger.info request.session_options.inspect
      home_root_path
    elsif
      app_root_path
    end
  end

  def after_sign_out_path_for(resource)
    app_root_path
  end

  def check_activation_status
    if current_system_user && !current_system_user.activated?
      Rails.logger.info "[SystemUser id=#{current_system_user.id}] to be forced to logout due to de-activated status"
      handle_inactive_status
    end
  end
 
  def client_ip
    request.env["HTTP_X_FORWARDED_FOR"]
  end

  def handle_route_not_found
    respond_to do |format|
      format.html { render partial: "shared/error404", formats: [:html], layout: "error_page", status: :not_found }
      format.js { render partial: "shared/error404", formats: [:js], status: :not_found }
    end
  end
 
  protected
  def handle_inactive_status
    Rails.logger.info 'handle_inactive_status'
    sign_out current_system_user if current_system_user
    flash[:alert] = "alert.inactive_account"  # login page want raw locale key due to devise behavior
    
    if request.xhr?
      render :nothing => true, :status => :unauthorized
    else
      redirect_to root_path
    end
  end

  def sid
    request.session_options[:id]
  end
  
  def handle_unauthorize
    Rails.logger.info 'handle_unauthorize'
    flash[:alert] = I18n.t("flash_message.not_authorize")

    if request.xhr?
      render :js => "window.location = '/home'"
    else
      redirect_to home_root_path
    end
  end
  
  def render_content(options={})
    @main_content = options[:file] || "#{params[:controller]}/#{params[:action]}"
    @sub_layout = options[:layout]

    respond_to do |format|
      format.html { render file: @main_content, formats: [:html], layout: false }
      format.js { render partial: "shared/main_content", formats: [:js] }
    end
  end
  
  def ap_layout
    #Rails.application.config.enable_ajax ? false : default_selected_function
    #request.xhr? ? false : default_selected_function
    false
  end
  
  def default_selected_function
    # TODO: determine what path to redirect to based on role/permission
    Rails.application.routes.recognize_path "home"
  end

  def handle_fatal_error(e)
    @from = params[:from]
    Rails.logger.error "#{e.message}"
    Rails.logger.error "#{e.backtrace.inspect}"

    respond_to do |format|
      format.html { render partial: "shared/error500", formats: [:html], layout: "error_page", status: :internal_server_error }
      format.js { render partial: "shared/error500", formats: [:js], status: :internal_server_error }
    end

    return
  end
end
