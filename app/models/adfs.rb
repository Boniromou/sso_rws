class Adfs < AuthSource

  def get_url
    "/saml/new"
  end

  def get_saml_settings(url_base, app_name)
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
    settings = idp_metadata_parser.parse_remote(auth_source_detail['data']['config_url'], false)
    settings.issuer                         = url_base + "/saml/metadata"
    settings.assertion_consumer_service_url = url_base + "/saml/acs?app_name=#{app_name}"
    settings.assertion_consumer_logout_service_url = url_base + "/saml/logout?app_name=#{app_name}"

    settings.private_key = auth_source_detail['data']['private_key']
    settings.certificate = auth_source_detail['data']['certificate']
    settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
    settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
    settings.security[:logout_requests_signed] = true
    settings.security[:digest_method] = auth_source_detail['data']['digest_method'].constantize
    settings.security[:signature_method] = auth_source_detail['data']['signature_method'].constantize
    settings
  end

  def create_adfs_user!(username, domain)
    SystemUser.register!(username, domain)
  end
end
