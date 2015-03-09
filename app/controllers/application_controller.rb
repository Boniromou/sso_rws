require 'admin_portal_error'

class ApplicationController < ActionController::Base
  layout false
  #layout proc {|controller| controller.request.xhr? ? false: "base" }
  include Pundit
  protect_from_forgery
  before_filter :set_locale, :authenticate_system_user!, :check_activation_status
  respond_to :html, :js
  alias_method :current_user, :current_system_user

  #rescue_from ::ActiveRecord::RecordInvalid, :with => :handle_invalid_error
  #rescue_from ::ActiveRecord::StaleObjectError, :with => :handle_unsync_error
  #rescue_from Exception, :with => :handle_fatal_error

  rescue_from Pundit::NotAuthorizedError, :with => :handle_unauthorize

  def set_locale
    I18n.locale = params[:locale] && I18n.available_locales.include?(params[:locale].to_sym) ? params[:locale] : I18n.default_locale
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(SystemUser)
      Rails.logger.info "A SystemUser logged in. Session=#{session.inspect}"
      #Rails.logger.info request.session_options.inspect
      Rails.application.routes.recognize_path default_selected_function
    elsif
      root_path
    end
  end

  def after_sign_out_path_for(resource)
    root_path
  end

  def check_activation_status
    if current_system_user && !current_system_user.activated?
      Rails.logger.info "[SystemUser id=#{current_system_user.id}] to be forced to logout due to de-activated status"
      handle_unauthorize
    end
  end
  
  # TODO: migrate these later
  #############################
  def administration_layout
    render :nothing => true, :layout => "administration"
  end
  
  def property_control_layout
    render :nothing => true, :layout => "property_control"
  end
  ##############################
 
  def client_ip
    request.env["HTTP_X_FORWARDED_FOR"]
  end
 
  protected
  def sid
    request.session_options[:id]
  end
  
  def handle_unauthorize
    #sign_out current_system_user if current_system_user
    flash[:alert] = "alert.unauthenticated"
    if request.xhr?
      #render :nothing => true, :status => :unauthorized
      render :js => "window.location = '/dashboard'"
    else
      redirect_to root_path
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
    "dashboard"
  end

  #def handle_unauthorize
  #  p "user unauthorizze!!!"
  #  flash[:alert] = 'unauthorize!' # TODO missing translation
  #  redirect_to root_path
  #end
end
