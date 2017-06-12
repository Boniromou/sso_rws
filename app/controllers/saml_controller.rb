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
    username = saml_response.attributes['username']
    session['nameid'] = saml_response.nameid
    session['sessionindex'] = saml_response.sessionindex
    session['username'] = username
    Rails.logger.info "attributes: #{saml_response.attributes.inspect}"
    Rails.logger.info "#{username} Sucessfully logged"
    Rails.logger.info "redirect to saml logout"
    redirect_to "#{URL_BASE}/saml/logout/?slo=true"
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
    logout_request = OneLogin::RubySaml::Logoutrequest.new()
    redirect_to(logout_request.create(settings))
  end

  # After sending an SP initiated LogoutRequest to the IdP, we need to accept
  # the LogoutResponse, verify it, then actually delete our session.
  def process_logout_response
    settings = get_saml_settings
    logout_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], settings, :get_params => params)
    Rails.logger.info "LogoutResponse is: #{logout_response.response.to_s}"
    if logout_response.success?
      auth_token = logout_response.in_response_to
      write_cookie(:auth_token, auth_token)
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
    params[:app_name]
  end

  def write_cookie(name, value, domain = :all)
    cookies.permanent[name] = {
      value: value,
      domain: domain
    }
  end

  def get_saml_settings
    AuthSource.find_by_token(request.remote_ip).get_saml_settings(get_url_base, app_name)
  end

  # value is an hash
  def add_cache(key, value)
    old = Rails.cache.read(key)
    value.merge!(old) if old
    Rails.logger.info "Rails cache, #{key}: #{Rails.cache.read(key)}"
    Rails.cache.write(key, value)
  end

  def handle_redirect
    redirect_to App.find_by_name(app_name).callback_url
  end
end
