class SamlController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:acs, :logout]
  skip_before_filter :authenticate_system_user!, :check_activation_status
  rescue_from Rigi::InvalidLogin, :with => :handle_invalid_login
  rescue_from Rigi::InvalidAuthorize, :with => :handle_invalid_authorize

  def new
    check_login_type!('Adfs')
    settings = get_saml_settings
    saml_request = OneLogin::RubySaml::Authrequest.new
    url = saml_request.create(settings)
    redirect_to(url)
  end

  def acs
    settings = get_saml_settings
    saml_response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :settings => settings)
    Rails.logger.info "AcsResponse is: #{saml_response.attributes.inspect}"

    session['nameid'] = saml_response.nameid
    session['sessionindex'] = saml_response.sessionindex
    session['username'] = saml_response.attributes['username'].downcase if saml_response.attributes['username']
    session['casinoids'] = convert_casino_ids(saml_response.attributes.all['casinoids'])
    session['app_name'] = params['app_name']
    session['second_authorize'] = params['second_authorize']
    Rails.logger.info "session: #{session.inspect}"

    redirect_to "#{URL_BASE}/saml/logout/?slo=true&app_name=#{params['app_name']}&second_authorize=#{params['second_authorize']}"
  end

  def metadata
    settings = get_saml_settings
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(settings, true)
  end

  def logout
    if params[:SAMLResponse]
      process_logout_response and return
    elsif params[:slo]
      return sp_logout_request
    else
      Rails.logger.error "invalid logout params: #{params.inspect}"
      raise "invalid logout params: #{params.inspect}"
    end
  end

  # Sending an SP initiated LogoutRequest to the IdP
  def sp_logout_request
    settings = get_saml_settings
    settings.sessionindex = session['sessionindex']
    settings.name_identifier_value = session['nameid']
    Rails.logger.info "app_name: #{app_name}"
    Rails.logger.info "session: #{session.inspect}"
    logout_request = OneLogin::RubySaml::Logoutrequest.new()
    redirect_to(logout_request.create(settings))
  end

  # After sending an SP initiated LogoutRequest to the IdP, we need to accept
  # the LogoutResponse, verify it, then actually delete our session.
  def process_logout_response
    Rails.logger.info "app_name: #{app_name}"
    Rails.logger.info "session: #{session.inspect}"
    settings = get_saml_settings
    logout_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], settings, :get_params => params)
    Rails.logger.info "LogoutResponse is: #{logout_response.response.to_s}"
    if logout_response.success?
      username, app_name, casinoids = session['username'], session['app_name'], session['casinoids']
      Rails.logger.info("app_name: #{app_name}, username: #{username}, casinoids: #{casinoids}")
      is_second_authorize? ? authorize_user!(username, app_name, casinoids) : authenticate!(username, app_name, casinoids)
    else
      raise "logout_response is failed"
    end
  end

  private
  def get_url_base
    URL_BASE
  end

  def authenticate!(username, app_name, casino_ids)
    system_user = AuthSource.find_by_token(get_client_ip).authenticate!(username, app_name, casino_ids)
    write_authenticate(system_user, app_name)
    Rails.logger.info("Login in success")
    handle_redirect(app_name)
  end

  def authorize_user!(username, app_name, casino_ids)
    system_user = AuthSource.find_by_token(get_client_ip).authorize!(username, app_name, casino_ids, auth_info['casino_id'], auth_info['permission'])
    Rails.logger.info("Authorize success")
    write_authorize_cookie({error_code: 'OK', error_message: 'Authorize successfully.', authorized_by: username, authorized_at: Time.now})
    redirect_to auth_info['callback_url']
  end

  def app_name
    params[:app_name] || session['app_name']
  end

  def second_authorize
    params[:second_authorize] || session['second_authorize']
  end

  def is_second_authorize?
    second_authorize.to_s == 'true'
  end

  def convert_casino_ids(casino_ids)
    return [] unless casino_ids
    casino_ids.collect {|casino_id| casino_id.delete('casinoid').to_i}
  end

  def get_saml_settings
    AuthSource.find_by_token(get_client_ip).get_saml_settings(get_url_base, app_name, is_second_authorize?)
  end

  def handle_redirect(app_name)
    redirect_to App.find_by_name(app_name).callback_url
  end

  def handle_invalid_login(e)
    if is_second_authorize?
      handle_invalid_authorize(e)
    else
      Rails.logger.error e.message
      Rails.logger.error e.backtrace
      @app_name = session['app_name']
      @error_info = {
        status: I18n.t('alert.authenticate_failed'),
        # message: I18n.t(e.error_message)
        note: I18n.t(e.error_message)
      }
      render layout: false, template: 'system_user_sessions/error_warning'
    end
  end

  def handle_invalid_authorize(e)
    Rails.logger.error e.error_message
    Rails.logger.error e.backtrace
    write_authorize_cookie({error_code: e.message, error_message: e.error_message})
    redirect_to auth_info['callback_url']
  end
end
