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
    Rails.logger.info "AcsResponse is: #{saml_response.response.to_s}"

    session['nameid'] = saml_response.nameid
    session['sessionindex'] = saml_response.sessionindex
    session['username'] = saml_response.attributes['username']
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
      return process_logout_response
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
      auth_token = logout_response.in_response_to
      write_cookie(:auth_token, auth_token)
      Rails.logger.info "write cookie auth_token: #{auth_token}"
      add_cache(auth_token, session.to_hash)
      handle_redirect
    else
      raise "logout_response is failed"
    end
  end

  def get_url_base
    URL_BASE
  end

  private
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
    settings = AuthSource.find_by_token(request.remote_ip).get_saml_settings(get_url_base, app_name)
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

  def handle_redirect
    redirect_to App.find_by_name(app_name).callback_url
  end
end
