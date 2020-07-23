class ApplicationController < ActionController::Base
  layout false
  include Pundit
  protect_from_forgery
  before_filter :set_locale, :authenticate_system_user!, :check_activation_status, :verify_request_scope
  respond_to :html, :js

  rescue_from Exception, :with => :handle_fatal_error
  rescue_from Pundit::NotAuthorizedError, :with => :handle_unauthorize

  def set_locale
    I18n.locale = params[:locale] && I18n.available_locales.include?(params[:locale].to_sym) ? params[:locale] : I18n.default_locale
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(SystemUser)
      Rails.logger.info "A SystemUser logged in. Session=#{session.inspect}"
      home_root_path
    elsif
      app_root_path
    end
  end

  def after_sign_out_path_for(resource)
    app_root_path
  end

  def check_activation_status
    if current_system_user && current_system_user.inactived?
      Rails.logger.info "[SystemUser id=#{current_system_user.id}] to be forced to logout due to de-activated status"
      handle_inactive_status
    end
  end

  def get_client_ip
    ip = request.env["X-Real-IP"]
    ip = request.env["HTTP_X_FORWARDED_FOR"] if !ip
    ip = request.remote_ip if !ip
    ip
  end

  def handle_route_not_found
    respond_to do |format|
      format.html { render partial: "shared/error404", formats: [:html], layout: "error_page", status: :not_found }
      format.js { render partial: "shared/error404", formats: [:js], status: :not_found }
    end
  end

  def write_authenticate(system_user, app_name)
    app_type = App.where(name: app_name).first.token_type || 'standard'
    send("#{app_type}_token", system_user, app_name)
  end

  def standard_token(system_user, app_name)
    uuid = SecureRandom.uuid
    name = app_name == 'report_portal' ? 'report_portal_auth_token' : 'auth_token'
    write_cookie(name.to_sym, uuid)
    add_cache(uuid, {:system_user => {:id => system_user.id, :username => system_user.username}})
  end

  def vue_token(system_user, app_name)
    name = "#{app_name}_auth_token"
    result = {
      id: system_user.id,
      app_name: app_name,
      sign_at: Time.now
    }
    write_cookie(name.to_sym, JWT.encode(result, 'test_key', 'HS256'))
  end

  def write_authorize_cookie(value)
    value.merge!({message_id: auth_info['message_id']})
    value = JWT.encode value, 'test_key', 'HS256'
    write_cookie(:second_auth_result, value)
  end

  def auth_info
    JWT.decode(cookies[:second_auth_info], 'test_key', true, { algorithm: 'HS256' })[0] if cookies[:second_auth_info]
  end

  def write_cookie(name, value, domain = :all)
    cookies[name] = {
      value: value,
      domain: domain
    }
  end

  def add_cache(key, value)
    old = Rails.cache.read(key)
    value.merge!(old) if old
    Rails.cache.write(key, value)
    Rails.logger.info "Rails cache, #{key}: #{Rails.cache.read(key)}"
  end

  def check_login_type!(type)
    auth_source = AuthSource.find_by_token(get_client_ip)
    raise 'Invalid login type' unless auth_source.type.downcase.include?(type)
  end

  protected
  class SystemUserContext
    attr_reader :system_user, :request_casino_id

    def initialize(system_user, request_casino_id)
      @system_user = system_user
      @request_casino_id = request_casino_id
    end
  end

  # e.g.
  #
  #   auditing(:audit_target => "system_user", :audit_action => "edit_roles") do
  #     # edit roles logic goes here...
  #   end
  #
  # without any argument, it follows convention as controller name and action name become audit_target and audit_action respectively
  #   auditing { ... }
  # => same as auditing(:audit_target => controller_name, :audit_action => action_name) { ... }
  #
  def auditing(*args, &block)
    options = args.extract_options!
    audit_target = options[:audit_target] || controller_name.singularize
    audit_action = options[:audit_action] || action_name
    action_by = options[:action_by] || "#{current_system_user.username}@#{current_system_user.domain.name}"
    sid = options[:session_id] || get_sid
    client_ip = options[:ip] || get_client_ip
    description = options[:description]

    AuditLog.compose(audit_target, audit_action, action_by, sid, client_ip, :description => description, &block)
  end

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

  def get_sid
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

  #
  # convention:
  #   policy scope/target name as controller resource name
  #   policy action name as controller action/api name
  #
  # e.g.
  #
  # MaintenancesController#index
  # => policy_target = "maintenance"
  # => action_name = "index"
  #
  # include the following line in MaintenancesController:
  #   before_filter :authorize_action, :only => [:index]
  #
  def authorize_action(record=nil, policy_def=nil)
    policy_def ||= "#{action_name}?".to_sym
    policy_target =
      if record.nil?
        controller_name.singularize.to_sym
      elsif record.is_a?(Array)
        record.first
      else
        record
      end

    Rails.logger.info "------ authorize action ------> target = #{policy_target}, action = #{policy_def}"
    authorize policy_target, policy_def
  end

  def pundit_user
    SystemUserContext.new(current_system_user, params[:casino_id])
  end

  def verify_request_scope
    casino_ids = []
    casino_ids << params[:casino_id] if params[:casino_id]
    casino_ids += params[:selected_casinos] if params[:selected_casinos]

    casino_ids.each do |casino_id|
      casino = Casino.find_by_id(casino_id)
      authorize casino, :same_group?
    end
  end
end
