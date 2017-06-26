require "feature_spec_helper"

describe SystemUsersController do
  fixtures :permissions, :role_permissions, :roles, :auth_sources

  before(:each) do
    create(:app, name: APP_NAME, callback_url: home_root_path)
    @root_user = create(:system_user, :admin, :with_casino_ids => [1000])
  end

  def login_as_root
    login("#{@root_user.username}@#{@root_user.domain.name}")
  end

  def format_time(time)
    time.getlocal.strftime("%Y-%m-%d %H:%M:%S") if time.present?
  end

  def verify_system_user_table_column_header
    col_headers = all("div#content table#system_user thead th")
    expect(col_headers.length).to eq 4
    expect(col_headers[0].text).to eq(I18n.t("user.user_name"))
    expect(col_headers[1].text).to eq(I18n.t("user.status"))
    expect(col_headers[2].text).to eq(I18n.t("property.title"))
    expect(col_headers[3].text).to eq(I18n.t("general.updated_at"))
  end

  describe "[4] List System user" do
    def casino_id_names_format(casino_id_names)
      return '' if casino_id_names.blank?
      rtn = "[#{casino_id_names.first[:name]}, #{casino_id_names.first[:id]}]"
      for i in 1...casino_id_names.length do
        rtn += ", [#{casino_id_names[i][:name]}, #{casino_id_names[i][:id]}]"
      end
      rtn
    end

    def verify_system_user_table_record(row_number, system_user)
      row_cells = all("div#content table#system_user tbody tr:nth-child(#{row_number}) td")
      expect(row_cells.length).to eq 4
      expect(row_cells[0].text).to eq "#{system_user.username}@#{system_user.domain.name}"
      if system_user.activated?
        expect(row_cells[1].text).to eq I18n.t("user.active")
      else
        expect(row_cells[1].text).to eq I18n.t("user.inactive")
      end
      expect(row_cells[2].text).to eq casino_id_names_format(system_user.active_casino_id_names)
      expect(row_cells[3].text).to eq format_time(system_user.updated_at)
    end

    before(:each) do
      user_manager_role = Role.find_by_name "user_manager"
      @system_user_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      @system_user_2 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1003])
      @system_user_3 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1003, 1007, 1014])

      it_support_role = Role.find_by_name "it_support"
      @system_user_4 = create(:system_user, :roles => [it_support_role], :with_casino_ids => [1003, 1007])
      @system_user_5 = create(:system_user, :roles => [it_support_role], :with_casino_ids => [])
    end

    it "[4.1] verify the list system user" do
      mock_ad_account_profile
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit system_users_path
      table_selector = "div#content table#system_user"
      rows = all("#{table_selector} tbody tr")
      users = [@root_user, @system_user_1, @system_user_2, @system_user_3, @system_user_4, @system_user_5]
      expect(rows.length).to eq users.length
      users.each_with_index do |user, index|
        verify_system_user_table_record(index + 1, user)
      end
    end

    it "[4.2] verify the list system non-1000 user" do
      mock_ad_account_profile('active', [1003])
      login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
      visit system_users_path
      table_selector = "div#content table#system_user"
      rows = all("#{table_selector} tbody tr")
      expect(rows.length).to eq 1
      verify_system_user_table_record(1, @system_user_2)
    end

    it "[4.3] filter suspended casino group user" do
      mock_ad_account_profile('active', [1003])
      login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
      @system_user_3.update_casinos([1007])
      visit system_users_path
      table_selector = "div#content table#system_user"
      rows = all("#{table_selector} tbody tr")
      expect(rows.length).to eq 1
      verify_system_user_table_record(1, @system_user_2)
    end

    it "[4.4] Only allow to view subset casino of user" do
      mock_ad_account_profile('active', [1003])
      @system_user_3.update_casinos([1003, 1007])

      login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
      visit system_users_path

      table_selector = "div#content table#system_user"
      rows = all("#{table_selector} tbody tr")
      expect(rows.length).to eq 1
      verify_system_user_table_record(1, @system_user_2)
    end
  end

  describe '[5] View system user' do
    def verify_system_user_profile_page(system_user, assert_edit_btn=true)
      visit system_user_path(:id => system_user.id)
      breadcrumb_dom = find("div#content div#breadcrumbs h2.page-title")
      expect(breadcrumb_dom).to have_content system_user.username
      expect(breadcrumb_dom).to have_content system_user.status ? I18n.t("user.active") : I18n.t("user.inactive")

      tbl = find("div#content div#systems_and_roles")

      if assert_edit_btn
        expect(tbl).to have_link(I18n.t("general.edit"))
      else
        expect(tbl).to have_no_link(I18n.t("general.edit"))
      end
    end

    before(:each) do
      user_manager_role = Role.find_by_name "user_manager"
      @system_user_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      it_support_role = Role.find_by_name "it_support"
      @system_user_2 = create(:system_user, :roles => [it_support_role], :with_casino_ids => [])
    end

    it '[5.1] Check Single user content' do
      login_as_root
      verify_system_user_profile_page(@root_user, false)
      logout(@root_user)
    end

    it '[5.2] Current user cannot edit role for himself' do
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      verify_system_user_profile_page(@system_user_1, false)
      logout(@system_user_1)
    end

    it '[5.3] Edit button is alwawys disabled in Root user' do
      login_as_root
      verify_system_user_profile_page(@root_user, false)
      logout(@root_user)
    end

    it '[5.4] Can see the edit buttons if the targeted users have no casino group' do
      login_as_root
      verify_system_user_profile_page(@system_user_2, true)
      logout(@root_user)
    end
  end

  describe '[7] Edit Roles' do
    before(:each) do
      @system_user_1 = create(:system_user, :with_casino_ids => [1000])
      @system_user_2 = create(:system_user, :with_casino_ids => [1000])
    end

    def verify_grant_role(click_cancel_button=false)
      r1 = Role.first
      app1 = App.first
      roles = Role.all.group_by { |role| role.app_id }
      apps = App.all
      login_as_root
      visit edit_roles_system_user_path(@system_user_1)
      main_panel = find("div#content")
      expect(main_panel).to have_content(@system_user_1.username)
      # verify the app name
      all("div#content fieldset section:nth-child(1)").each_with_index do |v, i|
        expect(v.text).to eq apps[i].name.titleize
      end
      # verify the role names
      all("div#content fieldset section:nth-child(2)").each_with_index do |v, i|
        if roles[i+1].present?
          roles[i+1].each do |role|
            expect(v).to have_content role.name.titleize
          end
        end
      end
      within ("div#content form") do
        choose("#{r1.name.titleize}")
        if click_cancel_button
          click_link(I18n.t("general.cancel"))
        else
          click_button(I18n.t("general.confirm"))
        end
      end
      unless click_cancel_button
        @system_user_1.reload
        expect(@system_user_1.roles.first.name).to eq r1.name
        user_profile = find("div#content table")
        expect(user_profile).to have_content "#{app1.name.titleize}"
        expect(user_profile).to have_content "#{r1.name.titleize}"
        check_flash_message I18n.t("success.edit_role", :user_name => @system_user_1.username)
      end
    end

    def verify_revoke_role
      r1 = Role.first
      app1 = App.first
      roles = Role.all.group_by { |role| role.app_id }
      apps = App.all
      @system_user_1.role_assignments.create!({:role_id => r1.id})
      @system_user_1.app_system_users.create!({:app_id => r1.app.id})
      login_as_root
      visit edit_roles_system_user_path(@system_user_1)
      main_panel = find("div#content")
      expect(main_panel).to have_content(@system_user_1.username)
      # verify the app name
      all("div#content fieldset section:nth-child(1)").each_with_index do |v, i|
        expect(v.text).to eq apps[i].name.titleize
      end
      # verify the role names
      all("div#content fieldset section:nth-child(2)").each_with_index do |v, i|
        if roles[i+1].present?
          roles[i+1].each do |role|
            expect(v).to have_content role.name.titleize
          end
        end
      end
      within ("div#content form") do
        radio_btn_1 = find("input##{app1.name}_#{r1.id}")
        expect(radio_btn_1[:checked]).to eq "checked"
        uncheck("enabled_#{app1.name}")
      end

      page.driver.post("/system_users/#{@system_user_1.id}/update_roles")
      visit system_user_path(@system_user_1)

      @system_user_1.reload
      expect(@system_user_1.roles.length).to eq 0
      user_profile = find("div#content div#systems_and_roles")
      expect(user_profile).not_to have_content "#{app1.name.titleize}"
      expect(user_profile).not_to have_content "#{r1.name.titleize}"
      check_flash_message I18n.t("success.edit_role", :user_name => @system_user_1.username)
    end

    it '[7.1] Grant role' do
      verify_grant_role
    end

    it '[7.2] revoke role' do
      verify_revoke_role
    end

    it '[7.3] Audit edit role' do
      verify_grant_role
      check_success_audit_log("system_user", "update", "edit_role", "portal.admin@example.com")
    end

    it '[7.4] Cancel edit role' do
      verify_grant_role(true)
      al = AuditLog.all
      expect(al.length).to eq 0
    end

    it '[7.5] Current user cannot edit role for himself (view system user)' do
      root_user = SystemUser.find_by_admin(1)
      login_as_root
      visit system_user_path(root_user)
      expect(page).to have_content(root_user.username)
      #expect(page).to have_content(I18n.t("user.status"))
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_no_button(I18n.t("user.lock"))
      expect(page).to have_content(I18n.t("role.role"))
      #expect(page).to have_content(I18n.t("role.root_user"))
      expect(page).to have_no_button(I18n.t("general.edit"))
    end
  end

  describe "[13] Switch main functional tab" do
    it "[13.1] Select User Management" do
      login_as_root
      visit '/home'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.user_management")).click
      expect(current_path).to eq(user_management_root_path)
      expect(page).to have_selector("div#inactived_system_user")
    end

    it "[13.2] Click Audit log" do
      login_as_root
      visit '/home'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.audit_log")).click
      expect(current_path).to eq(search_audit_logs_path)
    end

    it "[13.3] Select Role Management" do
      login_as_root
      visit '/home'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.role_management")).click
      expect(current_path).to eq(role_management_root_path)
    end
  end

  describe "[14] Role authorization" do
    fixtures :apps, :permissions, :role_permissions, :roles, :role_types

    before(:each) do
      user_manager_role = Role.find_by_name "user_manager"
      create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
    end

    it "[14.1] click unauthorized action" do
      auditor_role = Role.find_by_name "auditor"
      user_manager_role = Role.find_by_name "user_manager"

      auditor_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      auditor_2 = create(:system_user, :roles => [auditor_role], :with_casino_ids => [1000])
      login("#{auditor_1.username}@#{auditor_1.domain.name}")
      visit home_root_path
      visit system_user_path(:id => auditor_2.id)
      auditor_1.update_roles([auditor_role.id])
      auditor_1.reload
      edit_usr_btn_select = "div#content div#systems_and_roles a.btn"
      find(edit_usr_btn_select).click

      verify_unauthorized_request
    end

    it "[14.2] click link to the unauthorized page" do
      auditor_role = Role.find_by_name "auditor"
      auditor_1 = create(:system_user, :roles => [auditor_role], :with_casino_ids => [1000])
      login("#{auditor_1.username}@#{auditor_1.domain.name}")
      visit home_root_path
      visit user_management_root_path
      verify_unauthorized_request
    end

    it "[14.3] Search audit log (authorized)" do
      auditor_role = Role.find_by_name "auditor"
      auditor_1 = create(:system_user, :roles => [auditor_role], :with_casino_ids => [1000])
      login("#{auditor_1.username}@#{auditor_1.domain.name}")
      visit home_root_path
      visit search_audit_logs_path
      expect(current_path).to eq search_audit_logs_path
      verify_authorized_request
    end

    it "[14.4] Search audit log (unauthorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item(I18n.t("header.audit_log"), false)
    end

    it "[14.5] List System User (authorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
      click_link I18n.t("user.list_users")
      expect(find('a#exportUserRole').text).to eq I18n.t("general.export")
    end

    it "[14.6] List System User (unauthorized)" do
      auditor_role = Role.find_by_name "auditor"
      auditor_1 = create(:system_user, :roles => [auditor_role], :with_casino_ids => [1000])
      login("#{auditor_1.username}@#{auditor_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item(I18n.t("header.user_management"), false)
    end

    it "[14.7] View user profile (authroized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      user_manager_2 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
      click_link I18n.t("user.list_users")
      user_manager_2_profile_link_selector = "div#content table tbody tr:nth-child(2) td:first-child a"
      find(user_manager_2_profile_link_selector).click
      verify_authorized_request
    end

    it "[14.8] Grant roles (authorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      user_manager_2 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
      click_link I18n.t("user.list_users")
      user_manager_2_profile_link_selector = "div#content table tbody tr:nth-child(2) td:first-child a"
      find(user_manager_2_profile_link_selector).click
      click_link I18n.t("general.edit")
      expect(has_link?(I18n.t("general.cancel"))).to be true
      click_button I18n.t("general.confirm")
      verify_authorized_request
    end
  end

  describe "[24] Create System User", :js => true do
    def domain_array
      ['example.com', '1003.com', '1007.com', '1014.com']
    end

    def fill_in_user_info(username, domain)
      fill_in "system_user_username", :with => username
      select domain, :from => "system_user[domain]"
    end

    def test_click_create_btn(username)
      page.find("#modal_link").click
      wait_for_ajax
      expect(page).to have_content I18n.t("general.cancel")
      expect(page).to have_content I18n.t("general.confirm")
      expect(page).to have_content I18n.t("alert.create_system_user_confirm", :username => username)
      click_button I18n.t("general.confirm")
    end

    def mock_duplicated_user_create
      create(:system_user, :username => 'abc', :domain_name => '1003.com', :with_casino_ids => [1003])
      login_as_root
      visit new_system_user_path
      fill_in_user_info('abc', '1003.com')
      test_click_create_btn('abc@1003.com')
    end

    before(:each) do
      @it_support_role = Role.find_by_name "it_support"
    end

    it "[24.1] create system user success" do
      create(:system_user, :domain_name => '1003.com', :with_casino_ids => [1003])
      login_as_root
      visit new_system_user_path
      fill_in_user_info('   abc   ', '1003.com')
      mock_ad_account_profile('active', [1003])
      test_click_create_btn('abc@1003.com')
      expect(page).to have_content I18n.t("success.create_user", :username => 'abc@1003.com')
      expect(current_path).to eq new_system_user_path
    end

    it "[24.2] Display domains in create user page according to user domain casino mapping (1000)" do
      create(:domain, :name => '1003.com', :with_casino_ids => [1003])
      create(:domain, :name => '1007.com', :with_casino_ids => [1007])
      create(:domain, :name => '1014.com', :with_casino_ids => [1014])
      system_user = create(:system_user, :roles => [@it_support_role], :with_casino_ids => [1000])
      login("#{system_user.username}@#{system_user.domain.name}")
      visit new_system_user_path
      expect(page).to have_select("domain", :with_options => domain_array)
    end

    it "[24.3] Display domains in create user page according to user domain casino mapping (1003,1007)" do
      system_user = create(:system_user, :roles => [@it_support_role], :domain_name => '1003.com', :with_casino_ids => [1003])
      create(:domain, :name => '1014.com', :with_casino_ids => [1014])
      mock_ad_account_profile('active', [1003])
      login("#{system_user.username}@#{system_user.domain.name}")
      visit new_system_user_path
      expect(page).not_to have_select("domain", :with_options => domain_array)
      expect(page).to have_select("domain", :with_options => ["1003.com"])
    end

    it "[24.4] create system user fail with incorrect licensee casino group" do
      create(:system_user, :domain_name => '1003.com', :with_casino_ids => [1007])
      login_as_root
      visit new_system_user_path
      expect(page).to have_select("domain", :with_options => ["1003.com"])
      mock_ad_account_profile('active', [1003])
      fill_in_user_info('abc', '1003.com')
      test_click_create_btn('abc@1003.com')
      expect(page).to have_content I18n.t("alert.account_no_casino")
      expect(current_path).to eq new_system_user_path
    end

    it "[24.5] audit log for successfully create system user" do
      login_as_root
      visit new_system_user_path
      fill_in_user_info('abc', 'example.com')
      test_click_create_btn('abc@example.com')
      check_success_audit_log("system_user", "create", "create", "portal.admin@example.com")
    end

    it "[24.6] audit log for fail to create system user with incorrect licensee casino group" do
      create(:system_user, :domain_name => '1003.com', :with_casino_ids => [1007])
      login_as_root
      visit new_system_user_path
      mock_ad_account_profile('active', [1003])
      fill_in_user_info('abc', '1003.com')
      test_click_create_btn('abc@1003.com')
      check_fail_audit_log("system_user", "create", "create", "portal.admin@example.com")
    end

    it "[24.8] Create system user fail with invalid input" do
      create(:domain, :name => '1003.com')
      login_as_root
      visit new_system_user_path
      fill_in_user_info('', '1003.com')
      page.find("#modal_link").click
      expect(page).to have_content I18n.t("alert.invalid_username")
    end

    it "[24.9] Create system user fail with duplicated user in local DB" do
      mock_duplicated_user_create
      expect(page).to have_content I18n.t("alert.registered_account")
    end

    it "[24.10] audit log for fail to create system user with duplicated record in local DB" do
      mock_duplicated_user_create
      check_fail_audit_log("system_user", "create", "create", "portal.admin@example.com")
    end

    it "[24.11] Create system user fail with invalid input (space in system user name)" do
      system_user = create(:system_user, :roles => [@it_support_role], :domain_name => '1003.com', :with_casino_ids => [1003])
      mock_ad_account_profile('active', [1003])
      login("#{system_user.username}@#{system_user.domain.name}")
      visit new_system_user_path
      fill_in_user_info('ab    c', '1003.com')
      page.find("#modal_link").click
      expect(page).to have_content I18n.t("alert.invalid_username")
    end
  end

  describe "[28] Export system user list" do
    it "[28.1] successfully export", :js => true do
      login_as_root
      visit system_users_path
      expect(find("#exportUserRole").text).to eq I18n.t("general.export")
      expect(page.has_css?('div#pop_up_dialog', visible: false)).to eq true
      page.find("#exportUserRole").click
      expect(page.has_css?('div#pop_up_dialog', visible: true)).to eq true
      expect(find("div#pop_up_content").text).to eq I18n.t("confirm.export_user_role")
      find("button#confirm").click
      expect(page.has_css?('div#pop_up_dialog', visible: false)).to eq true
    end
  end
end
