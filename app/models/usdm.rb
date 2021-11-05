class Usdm < AuthSource
  def get_url(app_name)
    "#{URL_BASE}/ldap/new?app_name=#{app_name}&second_authorize=false"
  end

  def get_auth_url(app_name)
    "#{URL_BASE}/ldap_auth/new?app_name=#{app_name}&second_authorize=true"
  end

  def login!(username, password, app_name, session_token)
    valid_before_login!(username)
    system_user = SystemUser.find_by_username_with_domain(username)
    user_profile = usdm_login!(system_user.domain.auth_source_detail, username, password)
    casino_ids = filter_casino_ids(user_profile['casino_ids'], system_user.domain.get_casino_ids)
    authenticate!(username, app_name, user_profile['status'], casino_ids, session_token)
  end

  def create_user!(username, domain)
    domain_obj = Domain.where(:name => domain).first
    user_profile = retrieve_user_profile(domain_obj.auth_source_detail, "#{username}@#{domain}", domain_obj.get_casino_ids)
    raise Rigi::AccountNoCasino.new(I18n.t("alert.account_no_casino")) if user_profile['casino_ids'].blank?
    raise Rigi::InvalidLogin.new(I18n.t("alert.inactive_account")) if user_profile['status'] != SystemUser::ACTIVE
    SystemUser.register!(username, domain, user_profile['casino_ids'])
  end

  def authorize!(username, password, app_name, casino_id, permission)
    system_user = valid_before_login!(username)
    user_profile = usdm_login!(system_user.domain.auth_source_detail, username, password)
    casino_ids = filter_casino_ids(user_profile['casino_ids'], system_user.domain.get_casino_ids)
    system_user = authenticate_without_cache!(username, app_name, user_profile['status'], casino_ids)
    system_user.authorize!(app_name, casino_id, permission)
  end

  def change_password!(username, old_password, password)
    system_user = valid_before_login!(username)
    change_usdm_password(system_user.domain.auth_source_detail, username, old_password, password)
  end

  def retrieve_user_profile(auth_source_detail, username_with_domain, casino_ids)
    user_profile = retrieve_usdm_user!(auth_source_detail, username_with_domain)
    user_profile['casino_ids'] = filter_casino_ids(user_profile['casino_ids'], casino_ids)
    user_profile
  end

  private
  def valid_before_login!(username)
    system_user = SystemUser.find_by_username_with_domain(username)
    if system_user.nil?
      Rails.logger.error "SystemUser[username=#{username}] Login failed. Not a registered account"
      raise Rigi::InvalidLogin.new("alert.invalid_login")
    end
    system_user
  end

  def usdm_login!(auth_source_detail, username, password)
    requester = Requester::Usdms.new(auth_source_detail[:data]['config_url'])
    requester.login(username, password, auth_source_detail[:data]['secret_key'])['user']
  end

  def retrieve_usdm_user!(auth_source_detail, username)
    requester = Requester::Usdms.new(auth_source_detail[:data]['config_url'])
    requester.retrieve_user(username)['user']
  end

  def change_usdm_password(auth_source_detail, username, old_password, password)
    requester = Requester::Usdms.new(auth_source_detail[:data]['config_url'])
    requester.change_password(username, old_password, password, auth_source_detail[:data]['secret_key'])
  end

  def filter_casino_ids(casino_ids, domain_casino_ids)
    casino_ids && domain_casino_ids
  end
end
