class SamlController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:acs, :logout]
  skip_before_filter :authenticate_system_user!, :check_activation_status

  def write_cookie(name, value, domain = :all)
    cookies.permanent[name] = {
      # expires: 1.day.ago,
      value: value,
      domain: domain
    }
  end

  def new
    settings = Adfs.get_saml_settings(get_url_base)
    saml_request = OneLogin::RubySaml::Authrequest.new
    app_name = params['app_name'] || session['app_name']
    redirect_to 'https://www.google.com' and return if !app_name
    session['app_name'] = app_name
    url = saml_request.create(settings)
    redirect_to(url)
  end

  def acs
    settings = Adfs.get_saml_settings(get_url_base)
    @saml_response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :settings => settings)
    Rails.logger.info "attributes: #{@saml_response.attributes.inspect}"
    get_username
    session['nameid'] = @saml_response.nameid
    session['sessionindex'] = @saml_response.sessionindex
    session['username'] = @username
    Rails.logger.info "#{@username} Sucessfully logged"
    redirect_to 'https://test-sso.laxino.com/saml/logout/?slo=true'
  end

  def metadata
    settings = Adfs.get_saml_settings(get_url_base)
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(settings, true)
  end

  # Trigger SP and IdP initiated Logout requests
  def logout
    # print_session_id
    # If we're given a logout request, handle it in the IdP logout initiated method
    if params[:SAMLRequest]
      return idp_logout_request
    # We've been given a response back from the IdP
    elsif params[:SAMLResponse]
      return process_logout_response
    elsif params[:slo]
      return sp_logout_request
    else
      reset_session
    end
  end

  # Create an SP initiated SLO
  def sp_logout_request
    # LogoutRequest accepts plain browser requests w/o paramters
    settings = Adfs.get_saml_settings(get_url_base)
    settings.sessionindex = session['sessionindex']
    settings.name_identifier_value = session['nameid']

    logout_request = OneLogin::RubySaml::Logoutrequest.new()
    redirect_to(logout_request.create(settings))
  end

  # After sending an SP initiated LogoutRequest to the IdP, we need to accept
  # the LogoutResponse, verify it, then actually delete our session.
  def process_logout_response
    settings = Adfs.get_saml_settings(get_url_base)
    logout_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], settings, :get_params => params)

    logger.info "LogoutResponse is: #{logout_response.response.to_s}"
    if logout_response.success?
      auth_token = logout_response.in_response_to
      Rails.logger.info "auth_token: #{auth_token}"
      write_cookie(:auth_token, auth_token)
      add_cache(auth_token, session.to_hash)

      handle_redirect
    else
      redirect_to 'https://www.bing.com'
    end
  end

  # Method to handle IdP initiated logouts
  def idp_logout_request
    settings = Adfs.get_saml_settings(get_url_base)
    logout_request = OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest], :settings => settings)
    if not logout_request.is_valid?
      error_msg = "IdP initiated LogoutRequest was not valid!. Errors: #{logout_request.errors}"
      logger.error error_msg
      render :inline => error_msg
    end
    logger.info "IdP initiated Logout for #{logout_request.nameid}"

    # Actually log out this session
    reset_session

    logout_response = OneLogin::RubySaml::SloLogoutresponse.new.create(settings, logout_request.id, nil, :RelayState => params[:RelayState])
    redirect_to logout_response
  end

  def get_url_base
    "https://test-sso.laxino.com"
  end

  private
  # value is an hash
  def add_cache(key, value)
    old = Rails.cache.read(key)
    value.merge!(old) if old
    Rails.logger.info "Rails cache, #{key}: #{Rails.cache.read(key)}"
    Rails.cache.write(key, value)
  end

  def get_username
    @domain = 'mo.laxino.com'
    @name = @saml_response.attributes['username'].split('@').first
    @username = "#{@name}@#{@domain}"
    Rails.logger.info "name: #{@name} domain: #{@domain}"
  end

  def handle_redirect
    case session['app_name']
    when 'signature_verifier'
      redirect_to 'http://zhiming01.rnd.laxino.com:3000/index'
    when 'ssrs'
      redirect_to("https://test-ssrs.laxino.com/Reports/Pages/Folder.aspx")
    else
      redirect_to("https://www.google.com/")
    end
  end
end
