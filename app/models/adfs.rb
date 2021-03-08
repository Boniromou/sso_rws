class Adfs < AuthSource

  def get_url(app_name)
    "#{URL_BASE}/saml/new?app_name=#{app_name}&second_authorize=false"
  end

  def get_auth_url(app_name)
    "#{URL_BASE}/saml/new?app_name=#{app_name}&second_authorize=true"
  end

  def get_saml_settings(url_base, app_name, second_authorize = false)
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
    settings = idp_metadata_parser.parse_remote(auth_source_detail['data']['config_url'], false)
    settings.issuer                         = url_base + "/saml/metadata"
    settings.assertion_consumer_service_url = url_base + "/saml/acs?app_name=#{app_name}&second_authorize=#{second_authorize}"
    settings.assertion_consumer_logout_service_url = url_base + "/saml/logout?app_name=#{app_name}&second_authorize=#{second_authorize}"

    settings.authn_context_comparison = auth_source_detail['data']['comparison'] if auth_source_detail['data']['comparison']
    settings.private_key = auth_source_detail['data']['private_key']
    settings.certificate = auth_source_detail['data']['certificate']
    settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
    settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
    settings.security[:logout_requests_signed] = true
    settings.security[:digest_method] = auth_source_detail['data']['digest_method'].constantize
    settings.security[:signature_method] = auth_source_detail['data']['signature_method'].constantize
    settings
  end

  def authenticate!(username, app_name, casino_ids)
    system_user = SystemUser.find_by_username_with_domain(username)
    if system_user.nil?
      Rails.logger.error "SystemUser[username=#{username}] Login failed. Not a registered account"
      raise Rigi::InvalidLogin.new("alert.invalid_login")
    end
    casino_ids = system_user.domain.get_casino_ids & casino_ids
    super(username, app_name, SystemUser::ACTIVE, casino_ids)
  end

  def authorize!(username, app_name, casino_ids, target_casino, permission)
    system_user = SystemUser.find_by_username_with_domain(username)
    if system_user.nil?
      Rails.logger.error "SystemUser[username=#{username}] Login failed. Not a registered account"
      raise Rigi::InvalidLogin.new("alert.invalid_login")
    end
    casino_ids = system_user.domain.get_casino_ids & casino_ids
    system_user = authenticate_without_cache!(username, app_name, SystemUser::ACTIVE, casino_ids)
    system_user.authorize!(app_name, target_casino, permission)
  end

  def create_user!(username, domain)
    SystemUser.register_without_check!(username, domain)
  end
end
