require "feature_spec_helper"

describe DomainsController do
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

  def permission_with_domain_list
    create(:permission, target: "domain", action: "list", app_id: app_id)
  end

  def permission_with_domain_create
    create(:permission, target: "domain", action: "create", app_id: app_id)
  end

  def role_with_domain_list
    create(:role, app_id: app_id, with_permissions: [permission_with_domain_list])
  end

  def role_without_domain_list
    create(:role, app_id: app_id)
  end

  def role_with_domain_create
    create(:role, app_id: app_id, with_permissions: [permission_with_domain_list, permission_with_domain_create])
  end

  def user_with_domain_list
    casino_ids = [1000, 1007]
    create(:system_user, with_roles: [role_with_domain_list], with_casino_ids: casino_ids)
  end

  def user_without_domain_list
    casinos_ids = [1000, 1007]
    create(:system_user, with_roles: [role_without_domain_list], with_casino_ids: casinos_ids)
  end

  def user_with_domain_create
    return @current_user if @current_user

    casinos_ids = [1000, 1007]
    @current_user = create(:system_user, with_roles: [role_with_domain_create], with_casino_ids: casinos_ids)
  end

  def dropdown_domain_management?
    page.has_css?("#domain_management_link")
  end

  def login(system_user)
    mock_authenticate
    mock_retrieve_user_profile(system_user)
    visit login_path
    fill_in "system_user_username", :with => "#{system_user.username}@#{system_user.domain.name}"
    click_button I18n.t("general.login")
  end

  describe "[18] List Domain" do
    it "[18.1] No permission for list domain" do
      login(user_without_domain_list)
      visit home_root_path
      click_link_or_button("Home")
      expect(dropdown_domain_management?).to eq false
    end

    it "[18.2] List domain without create permission" do
      login(user_with_domain_list)
      visit domains_path

      expect(has_css?("table#domain tbody tr", count: Domain.count)).to eq true
      expect(has_css?("input#domain_name")).to eq false
      expect(has_css?("button#create_domain")).to eq false
    end

    it "[18.3] list domain with create permission" do
      login(user_with_domain_create)
      visit domains_path

      expect(has_css?("table#domain tbody tr", count: (Domain.count + 1))).to eq true
      expect(has_css?("input#domain_name")).to eq true
      expect(has_css?("button#create_domain")).to eq true
    end
  end

  describe "[19] Create Domain" do
    before :each do
      @domain_name = "1003.com"
      login(user_with_domain_create)
      visit domains_path
    end

    def click_confirm
      find("button#confirm").click
    end

    def fill_domain(domain_name = @domain_name)
      find("input#domain_name").set(domain_name)
    end

    def click_create_domain
      find("button#create_domain").click
    end

    def create_success
      fill_domain
      click_create_domain
      click_confirm
      check_flash_message(I18n.t('success.create_domain', {domain_name: @domain_name}))
      expect(has_text?(@domain_1003)).to eq true
    end

    it "[19.1] Create domain success" do
      create_success
    end

    it "[19.2] Create domain fail with invalid format case 1 input" do
    end

    it "[19.3] Create domain fail with invalid format case 2 input" do
    end

    it "[19.4] Audit for Create domain" do
      create_success
      filters = {
        audit_target: 'domain',
        action_type: 'create',
        action: 'create',
        action_status: 'success',
        action_by: user_with_domain_create.username
      }
      expect(AuditLog.where(filters)).not_to eq nil
    end

    it "[19.5] Create domain failed with duplicated domain" do
      create(:domain, name: @domain_name)
      fill_domain
      click_create_domain
      click_confirm
      check_flash_message(I18n.t("alert.invalid_domain"), {domain_name: @domain_name})
    end
  end
end
