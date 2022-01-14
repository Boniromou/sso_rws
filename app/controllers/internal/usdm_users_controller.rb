class Internal::UsdmUsersController < ApplicationController
  skip_before_filter :set_locale, :authenticate_system_user!, :check_activation_status, :verify_request_scope

  def login
    session_token = SecureRandom.uuid
    system_user = Usdm.new.login!(params[:username], params[:password], params[:app_name], session_token)
    render :json => {error_code: 'OK', error_msg: 'Request is now completed'}
  rescue Rigi::InvalidLogin, Rigi::InvalidDomain, Rigi::RemoteError => e
    Rails.logger.error("Login failed: #{e.error_message} #{e.backtrace}")
    render :json => {error_code: 'LoginFailed', error_msg: I18n.t(e.error_message)}
  rescue StandardError => e
    Rails.logger.error("Get user info error: #{e.message} #{e.backtrace}")
    render :json => {error_code: 'InternalServerError', error_msg: e.message}
  end

  def get_info
    user = SystemUser.find_by_username_with_domain(params[:username])
    raise Rigi::InvalidUsername.new unless user
    profile = get_profile(user)
    permissions = get_permissions(user, params[:app_name])
    render :json => {error_code: 'OK', error_msg: 'Request is now completed', data: {profile: profile, permissions: permissions}}
  rescue Rigi::InvalidUsername => e
    Rails.logger.error("user not found")
    render :json => {error_code: 'InvalidUsername', error_msg: 'system user not found'}
  rescue StandardError => e
    Rails.logger.error("Get user info error: #{e.message} #{e.backtrace}")
    render :json => {error_code: 'InternalServerError', error_msg: e.message}
  end

  def validate_permission
    user = SystemUser.find_by_username_with_domain(params[:username])
    raise Rigi::InvalidUsername.new unless user
    if !user.admin && params[:permission] != 'nopermission'
      permission_info = Rails.cache.read("#{params['app_name']}:permissions:#{user.id}")
      raise Rigi::InvalidPermission.new('Permission info not found') if permission_info.blank?
      target, action = params[:permission].split('-')
      permissions = permission_info[:permissions][:permissions][target.to_sym]
      raise Rigi::InvalidPermission.new('Invalid permission') if permissions.blank? || !permissions.include?(action)
    end
    render :json => {error_code: 'OK', error_msg: 'Request is now completed'}
  rescue Rigi::PortalError => e
    Rails.logger.error("validate permission error: #{e.error_message}")
    render :json => {error_code: e.class.name.demodulize, error_msg: e.error_message}
  rescue StandardError => e
    Rails.logger.error("validate permission error: #{e.message} #{e.backtrace}")
    render :json => {error_code: 'InternalServerError', error_msg: e.message}
  end

  def change_password
    system_user = Usdm.new.change_password!(params[:username], params[:old_password], params[:new_password])
    render :json => {error_code: 'OK', error_msg: 'Request is now completed'}
  rescue Rigi::InvalidLogin, Rigi::InvalidDomain, Rigi::RemoteError => e
    Rails.logger.error "SystemUser[username=#{params[:username]}] reset password failed: #{e.error_message}"
    render :json => {error_code: e.class.name.demodulize, error_msg: e.error_message}
  rescue StandardError => e
    Rails.logger.error("change password error: #{e.message} #{e.backtrace}")
    render :json => {error_code: 'InternalServerError', error_msg: e.message}
  end

  private
  def get_profile(user)
    casinos = user.active_casinos
    casino_ids = casinos.map(&:id)
    licensee = casinos.first.licensee if casinos.present?
    properties = Property.where(:casino_id => casino_ids).pluck(:id)
    profile = {
      :status => user.status,
      :admin => user.admin,
      :username_with_domain => "#{user.username}@#{user.domain.name}",
      :casino_ids => casino_ids,
      :licensee_id => licensee.try(:id),
      :licensee_name => licensee.try(:name),
      :property_ids => properties,
      :timezone => licensee.try(:timezone) || DEFAULT_TIMEZONE
    }
    profile.merge!(get_policy_casinos(user))
  end

  def get_permissions(user, app_name)
    return ['admin'] if user.admin
    app = App.find_by_name(app_name)
    permissions = []
    roles = user.roles.includes(:role_permissions => :permission).where(roles: {app_id: app.id}).where(permissions: {app_id: app.id})
    roles.each do |r|
      permissions += r.permissions.map{|p| "#{p.target}-#{p.action}" }
    end
    permissions.uniq
  end

  def get_policy_casinos(user)
    casinos = (user.is_admin? || user.has_admin_casino?) ? Casino.all : user.active_casinos
    casino_ids = casinos.map(&:id)
    properties = Property.where(:casino_id => casino_ids).as_json(only: [:id, :name])
    casinos = casinos.as_json(only: [:id, :name])
    {policy_casinos: casinos, policy_properties: properties}
  end
end
