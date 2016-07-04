module DomainCasinosControllerSpecHelper
  def target
    'domain_casino_mapping'
  end

  def mock_authenticate
    allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
  end

  def mock_retrieve_user_profile(system_user)
    res = {status: true, casino_ids: system_user.active_casino_ids}
    allow_any_instance_of(AuthSourceLdap).to receive(:retrieve_user_profile).and_return(res)
  end

  def app_name
    "user_management"
  end

  def app_sso
    app = App.where(:name => app_name).first
    return app if app
    create(:app, name: app_name)
  end

  def app_id
    app_sso.id
  end

  def find_create_permission(info)
    permission = Permission.where(info).first
    return permission if permission
    create(:permission, info)
  end

  def permission_with_domain_casino_list
    info = {target: target, name: "list", action: "list", app_id: app_id}
    find_create_permission(info)
  end


  def permission_with_domain_casino_create
    info = {target: target, name: "create", action: "create", app_id: app_id}
    find_create_permission(info)
  end

  def permission_with_domain_casino_inactive
    info = {target: target, name: "inactive", action: "inactive", app_id: app_id}
    find_create_permission(info)
  end

  def permission_with_domain_casino_change_log
    info = {target: target, name: "list_log", action: 'list_log', app_id: app_id}
    find_create_permission(info)
  end

  def role_without_domain_casino_list
    create(:role, name: 'role_without_domain_casino_list', app_id: app_id)
  end

  def role_with_domain_casino_list
    create(:role, name: 'role_with_domain_casino_list', app_id: app_id, with_permissions: [permission_with_domain_casino_list])
  end

  def role_with_domain_casino_create
    create(:role, name: 'role_with_domain_casino_create', app_id: app_id, with_permissions: [permission_with_domain_casino_list, permission_with_domain_casino_create])
  end

  def role_with_domain_casino_inactive
    create(:role, name: 'role_with_domain_casino_inactive', app_id: app_id, with_permissions: [permission_with_domain_casino_list, permission_with_domain_casino_inactive])
  end

  def role_with_domain_casino_change_log
    create(:role, name: 'role_with_domain_casino_change_log', app_id: app_id, with_permissions: [permission_with_domain_casino_list, permission_with_domain_casino_change_log])
  end

  def user_without_domain_casino_list
    return @current_user if @current_user

    casinos_ids = [1000, 1003, 1007]
    @current_user = create(:system_user, with_roles: [role_without_domain_casino_list], with_casino_ids: casinos_ids)
  end

  def user_with_domain_casino_list
    return @current_user if @current_user

    casino_ids = [1000, 1003, 1007]
    @current_user = create(:system_user, with_roles: [role_with_domain_casino_list], with_casino_ids: casino_ids)
  end

  def user_with_domain_casino_create
    return @current_user if @current_user

    casinos_ids = [1000, 1003, 1007]
    @current_user = create(:system_user, with_roles: [role_with_domain_casino_create], with_casino_ids: casinos_ids)
  end

  def user_with_domain_casino_inactive
    return @current_user if @current_user

    casinos_ids = [1000, 1003, 1007]
    @current_user = create(:system_user, with_roles: [role_with_domain_casino_inactive], with_casino_ids: casinos_ids)
  end

  def user_with_domain_casino_change_log
    return @current_user if @current_user

    casinos_ids = [1000, 1003, 1007]
    @current_user = create(:system_user, with_roles: [role_with_domain_casino_change_log], with_casino_ids: casinos_ids)
  end

  def user_with_admin
    return @current_user if @current_user
    @current_user = create(:system_user, :admin)
  end

  def login(system_user)
    mock_authenticate
    mock_retrieve_user_profile(system_user)
    visit login_path
    begin
      fill_in "system_user_username", :with => "#{system_user.username}@#{system_user.domain.name}"
      click_button I18n.t("general.login")
    rescue Exception => e
    end
  end

  def before_create_domain_casino
    login(user_with_domain_casino_create)

    @domain_name = '1003.com'
    @casino_ids = [1000, 1003, 1007]
    @casino_name = 'MockUp'

    info = {name: @domain_name}
    @domain_1003 = Domain.where(info).first
    @domain_1003 = create(:domain, info) if !@domain_1003

    info = {id: @casino_ids[0]}
    @casino_mockup = Casino.where(info).first
    if @casino_mockup
      @casino_mockup.name = @casino_name
      @casino_mockup.save!
    else
      info[:name] = @casino_name
      @casino_mockup = create(:casino, info)
    end

    visit domain_casinos_path
  end

  def select_domain(domain_name = @domain_name)
    select(domain_name, from: 'domain_id')
  end

  def select_casino(casino_name = @casino_name)
    select(casino_name, from: 'casino_id')
  end

  def click_create_domain_casino
    find("button#create_domain_casino").click
  end

  def check_domain_casino(domain_name = @domain_name, casino_name = @casino_name)
  end

  def general_create_domain_casino
    select_domain
    select_casino
    click_create_domain_casino
  end

  def before_inactive_domain_casino
    login(user_with_domain_casino_inactive)

    @domain_name = '1003.com'
    @casino_ids = [1000, 1003, 1007]
    @casino_name = 'MockUp'

    info = {name: @domain_name}
    @domain_1003 = Domain.where(info).first
    @domain_1003 = create(:domain, info) if !@domain_1003

    info = {id: @casino_ids[0]}
    @casino_mockup = Casino.where(info).first
    if @casino_mockup
      @casino_mockup.name = @casino_name
      @casino_mockup.save!
    else
      info[:name] = @casino_name
      @casino_mockup = create(:casino, info)
    end

    @domain_casino = create(:domains_casino, domain_id: @domain_1003.id, casino_id: @casino_mockup.id)

    visit domain_casinos_path
  end

  def inactive_domain_casino(domain_name = @domain_name, casino_name = @casino_name)
    all('tr').each do |node|
      within(node) do
        if(has_text?(domain_name) && has_text?(casino_name))
          find(".btn").click
        end
      end
    end
  end

  def delete_domain_casino_success
    inactive_domain_casino
    check_flash_message(I18n.t("success.inactive_domain_casino", {domain_name: @domain_name, casino_name: @casino_name}))
  end

  def delete_domain_casino_failed
    DomainsCasino.where(domain_id: @domain_1003.id, casino_id: @casino_mockup.id).first.inactive
    inactive_domain_casino
    check_flash_message(I18n.t("alert.domain_casino_not_found", {domain_name: @domain_name, casino_name: @casino_name}))
  end

  def click_log
    # click_log
  end

  def check_change_log?(infos)
    values = infos.values
    all("tr").each do |node|
      within(node) do
        count = 0
        values.each do |value|
          count += 1 if(has_text?(value))
        end
        return true if count == values.length
      end
    end
    return false
  end
end