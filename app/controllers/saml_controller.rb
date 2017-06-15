class SamlController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:acs, :logout]
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def new
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
    session['username'] = saml_response.attributes['username']
    session['casinoid'] = saml_response.attributes['casinoid'].delete('casinoid').to_i
    app_name = params['app_name']
    session['app_name'] = app_name
    Rails.logger.info "session: #{session.inspect}"

    redirect_to "#{URL_BASE}/saml/logout/?slo=true&app_name=#{app_name}"
  end

  def metadata
    settings = get_saml_settings
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(settings, true)
  end

  def logout
    if params[:SAMLResponse]
      begin
        process_logout_response and return
      rescue Rigi::InvalidLogin => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace
        @app_name = session['app_name']
        @error_info = {
          status: I18n.t('alert.authenticate_failed'),
          # message: I18n.t(e.error_message)
          note: I18n.t(e.error_message)
        }
        reset_session
        render layout: false, template: 'system_user_sessions/error_warning'
      end
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
      username, app_name, casinoid = session['username'], session['app_name'], session['casinoid'].to_i
      Rails.logger.info("app_name: #{app_name}, username: #{username}, casinoid: #{casinoid}")
      system_user = authenticate!(username, app_name, [casinoid])
      write_authenticate(system_user)
      Rails.logger.info("Login in success")
      reset_session
      handle_redirect(app_name)
    else
      raise "logout_response is failed"
    end
  end

  private
  def get_url_base
    URL_BASE
  end

  def authenticate!(username, app_name, casino_ids)
    AuthSource.find_by_token(get_client_ip).authenticate!(username, app_name, true, casino_ids)
  end

  def app_name
    params[:app_name] || session['app_name']
  end

  def write_cookie(name, value, domain = :all)
    cookies.permanent[name] = {
      value: value,
      domain: domain
    }
  end

  def get_saml_settings
    settings = AuthSource.find_by_token(get_client_ip).get_saml_settings(get_url_base, app_name)
    if !app_name
      settings.assertion_consumer_service_url = get_url_base + "/saml/acs"
      settings.assertion_consumer_logout_service_url = get_url_base + "/saml/logout"
    end
    settings
  end

  # value is an hash
  def add_cache(key, value)
    old = Rails.cache.read(key)
    value.merge!(old) if old
    Rails.cache.write(key, value)
    Rails.logger.info "Rails cache, #{key}: #{value}"
  end

  def handle_redirect(app_name)
    redirect_to App.find_by_name(app_name).callback_url
  end
end
