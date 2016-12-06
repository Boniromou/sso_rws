require "feature_spec_helper"

describe DomainsController do
  def create_permission(target, action)
    info = {target: target, name: action, action: action, app_id: @app_id}
    permission = Permission.where(info).first
    return permission if permission
    create(:permission, info)
  end

  def login_user(permissions=[], casino_ids=[1000])
    role = create(:role, app_id: @app_id, with_permissions: permissions)
    @system_user = create(:system_user, :roles => [role], :with_casino_ids => casino_ids)
    mock_ad_account_profile(true, casino_ids)
    login("#{@system_user.username}@#{@system_user.domain.name}")
  end

  def login_with_permission
    login_user([@permission_list, @permission_create, @permission_update, @permission_list_log])
  end

  def domain_data
    {
      "domain_name" => "   1003.com   ",
      "auth_source_name" => "hqidc_ldap",
      "auth_source_host" => "0.0.0.0",
      "auth_source_port" => "3268",
      "auth_source_account" => "test@1003.com",
      "auth_source_account_password" => "cccccc",
      "auth_source_base_dn" => "dc=1003, dc=com",
      "auth_source_admin_account" => "admin@1003.com",
      "auth_source_admin_password" => "dddddd"
    }
  end

  def fill_in_form
    @domain_data.each do |key, value|
      fill_in "domain_#{key}", :with => value
    end
    click_link_or_button I18n.t("general.confirm")
  end

  before(:each) do
    app = create(:app, name: APP_NAME)
    @app_id = app.id
    @permission_list = create_permission('domain_ldap', 'list')
    @permission_create = create_permission('domain_ldap', 'create')
    @permission_update = create_permission('domain_ldap', 'update')
    @permission_list_log = create_permission('domain_ldap', 'list_log')
  end

  describe "[18] List Domain" do
    def check_table
      expect(has_css?("table#domain_ldap tbody tr", count: Domain.count)).to eq true
    end

    it "[18.1] No permission for list domain-LDAP" do
      login_user
      visit home_root_path
      click_link_or_button("Home")
      expect(page.has_css?("#domain_management_link")).to eq false
    end

    it "[18.2] List domain-LDAP without create permission" do
      login_user([@permission_list])
      visit domains_path
      check_table
      expect(has_css?("#create_domain_ldap")).to eq false
      titles = [I18n.t('domain.name'), I18n.t('domain_ldap.ldap_name'), I18n.t('domain_ldap.host'), I18n.t('domain_ldap.port'), I18n.t('domain_ldap.account'), I18n.t('domain_ldap.base_dn'), I18n.t('domain_ldap.admin_account'), I18n.t('general.updated_at'), I18n.t("general.operation")]
      page.all('table#domain_ldap thead tr th').each_with_index do |th, index|
        expect(th.text).to eq titles[index]
      end
    end

    it "[18.3] list domain-LDAP with create permission" do
      login_with_permission
      visit domains_path
      check_table
      expect(has_css?("#create_domain_ldap")).to eq true
    end

    it "[18.4] List domain-LDAP without edit permission" do
      login_user([@permission_list])
      visit domains_path
      check_table
      expect(has_css?("#edit")).to eq false
    end

    it "[18.5] list domain-LDAP with edit permission" do
      login_with_permission
      visit domains_path
      check_table
      expect(has_css?("#edit")).to eq true
    end
  end

  describe "[19] Create Domain" do
    before(:each) do
      @domain_data = domain_data
      login_with_permission
      visit new_domain_path
    end

    it "[19.1] Create domain-LDAP success" do
      fill_in_form
      check_flash_message I18n.t('domain_ldap.create_domain_ldap_success')
      expect(current_path).to eq(domains_path)
      within("table#domain_ldap tbody tr:last-child") {
        @domain_data.delete("auth_source_account_password")
        @domain_data.delete("auth_source_admin_password")
        @domain_data.each_value do |value|
          expect_have_content value.strip
        end
      }
    end

    it "[19.2] Create domain-LDAP fail with invalid format case 1 input" do
      @domain_data["domain_name"] = "1003"
      fill_in_form
      check_flash_message I18n.t('alert.invalid_domain')
      expect(find("#domain_domain_name").value).to eq "1003"
    end

    it "[19.3] Create domain-LDAP fail with invalid format case 2 input" do
      @domain_data["domain_name"] = ".com"
      fill_in_form
      check_flash_message I18n.t('alert.invalid_domain')
      expect(find("#domain_domain_name").value).to eq ".com"
    end

    it "[19.4] Audit for Create domain-LDAP" do
      fill_in_form
      check_success_audit_log("domain_ldap", 'create', 'create', "#{@system_user.username}@#{@system_user.domain.name}")
    end

    it "[19.5] Create domain-LDAP fail with duplicated domain" do
      create(:domain, name: "1003.com")
      fill_in_form
      check_flash_message I18n.t('alert.domain_duplicated')
    end

    it "[19.6] Create domain-LDAP fail with duplicated LDAP" do
      create(:auth_source, name: "hqidc_ldap")
      fill_in_form
      check_flash_message I18n.t('alert.ldap_duplicated')
    end

    it "[19.7] Create domain-LDAP fail with missing input" do
      @domain_data["domain_name"] = ""
      fill_in_form
      check_flash_message I18n.t('alert.invalid_params')
    end
  end

  describe "[34] Domain-LDAP change log" do
    def check_change_log(domain, action, from, to, action_by)
      within("table#domain_ldap_change_logs_table tbody tr:nth-child(1)") {
        expect_have_content(domain)
        expect_have_content(action)
        expect_have_content(from)
        expect_have_content(to)
        expect_have_content(action_by)
      }
    end

    before(:each) do
      @domain_data = domain_data
    end

    it "[34.1] No Premission for List Domain Licensee mapping change log" do
      login_user([@permission_list, @permission_create, @permission_update])
      visit domains_path
      expect(has_text?(I18n.t("general.log"))).to eq false
    end

    it "[34.2] List Domain Licensee mapping change log" do
      login_with_permission
      visit index_domain_ldap_change_logs_path
      titles = [I18n.t('domain.name'), I18n.t('change_log.action'), I18n.t('change_log.from'), I18n.t('change_log.to'), I18n.t('change_log.action_at'), I18n.t('change_log.action_by')]
      page.all('div#domain_licensee_change_logs table thead tr th').each_with_index do |th, index|
        expect(th.text).to eq titles[index]
      end
    end

    it "[34.3] Create change log for create Domain Licensee mapping" do
      login_with_permission
      visit new_domain_path
      fill_in_form
      visit index_domain_ldap_change_logs_path
      to = "account:test@1003.com; account_password:******; admin_account:admin@1003.com; admin_password:******; base_dn:dc=1003, dc=com; host:0.0.0.0; name:hqidc_ldap; port:3268"
      check_change_log(@domain_data["domain_name"].strip, "Create", "", to, "#{@system_user.username}@#{@system_user.domain.name}")
    end

    it "[34.4] Create change log for edit Domain Licensee mapping" do
      auth_source = create(:auth_source)
      domain = create(:domain, name: "1003.com", auth_source_id: auth_source.id)
      login_with_permission
      visit domains_path
      find("#edit_#{domain.id}").click
      fill_in "domain_auth_source_name", :with => "hqidc_ldap"
      fill_in "domain_auth_source_host", :with => "10.10.10.10"
      click_link_or_button I18n.t("general.confirm")
      visit index_domain_ldap_change_logs_path
      from = "host:#{auth_source.host}; name:#{auth_source.name}"
      to = "host:10.10.10.10; name:hqidc_ldap"
      check_change_log(domain.name, "Edit", from, to, "#{@system_user.username}@#{@system_user.domain.name}")
    end
  end

  describe "[35] Edit Domain-LDAP" do
    def edit_form(ldap_name="hqidc_ldap")
      fill_in "domain_auth_source_name", :with => ldap_name
      click_link_or_button I18n.t("general.confirm")
    end

    before(:each) do
      @auth_source = create(:auth_source)
      @domain = create(:domain, name: "1003.com", auth_source_id: @auth_source.id)
      login_with_permission
      visit domains_path
      find("#edit_#{@domain.id}").click
    end

    it "[35.1] Edit domain-LDAP success" do
      edit_form
      check_flash_message I18n.t('domain_ldap.edit_domain_ldap_success')
      expect(current_path).to eq(domains_path)
      values = [@domain.name, "hqidc_ldap", @auth_source.host, @auth_source.port, @auth_source.account, @auth_source.base_dn, @auth_source.admin_account]
      within("table#domain_ldap tbody tr:nth-child(1)") {
        values.each do |value|
          expect_have_content value
        end
      }
    end

    it "[35.2] Audit for Edit domain-LDAP" do
      edit_form
      check_success_audit_log("domain_ldap", 'edit', 'edit', "#{@system_user.username}@#{@system_user.domain.name}")
    end

    it "[35.3] Edit domain-LDAP fail with duplicated LDAP" do
      create(:auth_source, name: "hqidc_ldap")
      edit_form
      check_flash_message I18n.t('alert.ldap_duplicated')
    end

    it "[35.4] Edit domain-LDAP fail with missing input" do
      edit_form("")
      check_flash_message I18n.t('alert.invalid_params')
    end

    it "[35.5] Retrieve domain-LDAP data success and disable the domain textbox" do
      domain = {
                 "domain_domain_name" => @domain.name,
                 "domain_auth_source_name" => @auth_source.name,
                 "domain_auth_source_host" => @auth_source.host,
                 "domain_auth_source_port" => @auth_source.port,
                 "domain_auth_source_account" => @auth_source.account,
                 "domain_auth_source_account_password" => @auth_source.account_password,
                 "domain_auth_source_base_dn" => @auth_source.base_dn,
                 "domain_auth_source_admin_account" => @auth_source.admin_account,
                 "domain_auth_source_admin_password" => @auth_source.admin_password
               }
      domain.each do |key, value|
        expect(find("##{key}").value).to eq value.to_s
      end
    end
  end
end