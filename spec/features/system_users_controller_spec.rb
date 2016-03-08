require "feature_spec_helper"

describe SystemUsersController do
  fixtures :apps, :permissions, :role_permissions, :roles, :licensees, :domains

  before(:each) do
    licensee = Licensee.first
    domain = Domain.first
    @root_user = create(:system_user, :admin, :with_casino_ids => [1000], :domain_id => domain.id, :licensee_id => licensee.id)
    user_manager_role = Role.find_by_name "user_manager"
    @system_user_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000], :domain_id => domain.id, :licensee_id => licensee.id)
    @system_user_2 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1003], :domain_id => domain.id, :licensee_id => licensee.id)
    @system_user_3 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1003, 1007, 1014], :domain_id => domain.id, :licensee_id => licensee.id)
  end

  def verify_system_user_table_column_header
    col_headers = all("div#content table#system_user thead th")
    expect(col_headers.length).to eq 3
    expect(col_headers[0].text).to eq(I18n.t("user.user_name"))
    expect(col_headers[1].text).to eq(I18n.t("user.status"))
    expect(col_headers[2].text).to eq(I18n.t("property.title"))
  end

  def verify_system_user_table_record(row_number, system_user_name, displayed_status, casino)
    row_cells = all("div#content table#system_user tbody tr:nth-child(#{row_number}) td")
    expect(row_cells.length).to eq 3
    expect(row_cells[0].text).to eq system_user_name
    expect(row_cells[1].text).to eq displayed_status
    expect(row_cells[2].text).to eq casino
  end
  
  describe "[4] List System user" do
    it "[4.1] verify the list system user" do
      mock_ad_account_profile(true, [1000])
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit system_users_path
      table_selector = "div#content table#system_user"
      rows = all("#{table_selector} tbody tr")
      expect(rows.length).to eq 4
      verify_system_user_table_record(1, @root_user.username, I18n.t("user.active"), "[1000]")
      verify_system_user_table_record(2, @system_user_1.username, I18n.t("user.active"), "[1000]")
      verify_system_user_table_record(3, @system_user_2.username, I18n.t("user.active"), "[1003]")
      verify_system_user_table_record(4, @system_user_3.username, I18n.t("user.active"), "[1003, 1007, 1014]")
    end

    it "[4.2] verify the list system non-1000 user" do
      mock_ad_account_profile(true, [1003])
      login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
      visit system_users_path
      table_selector = "div#content table#system_user"
      rows = all("#{table_selector} tbody tr")
      expect(rows.length).to eq 1
      verify_system_user_table_record(1, @system_user_2.username, I18n.t("user.active"), "[1003]")
      #verify_system_user_table_record(2, @system_user_3.username, I18n.t("user.active"), "[1003, 1007, 1014]")
    end

    it "[4.3] filter suspended casino group user" do
      mock_ad_account_profile(true, [1003])
      login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
      @system_user_3.update_casinos([1007])
      visit system_users_path
      table_selector = "div#content table#system_user"
      rows = all("#{table_selector} tbody tr")
      expect(rows.length).to eq 1
      verify_system_user_table_record(1, @system_user_2.username, I18n.t("user.active"), "[1003]")
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
        expect(tbl).to have_button(I18n.t("general.edit"))
      else
        expect(tbl).to have_no_button(I18n.t("general.edit"))
      end
    end

    it '[5.1] Check Single user content' do
      login("#{@root_user.username}@#{@root_user.domain.name}")
      verify_system_user_profile_page(@root_user, false)
      logout(@root_user)
    end

    it '[5.2] Current user cannot edit role for himself' do
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      verify_system_user_profile_page(@system_user_1, false)
      logout(@system_user_1)
    end

    it '[5.3] Edit button is alwawys disabled in Root user' do
      login("#{@root_user.username}@#{@root_user.domain.name}")
      verify_system_user_profile_page(@root_user, false)
      logout(@root_user)
    end
  end

  describe '[7] Edit Roles' do
    before(:each) do
      @system_user_1 = create(:system_user, :with_casino_ids => [1000])
      @system_user_2 = create(:system_user, :with_casino_ids => [1000])
      #@user_manager = Role.first
      #@helpdesk = Role.find_by_name("helpdesk")
      #@system_user_2.role_assignments.create!({:role_id => @helpdesk.id})
    end

    def verify_grant_role(click_cancel_button=false)
      r1 = Role.first
      app1 = App.first
      roles = Role.all.group_by { |role| role.app_id }
      apps = App.all
      #@system_user_1.role_assignments.create!({:role_id => r1.id})
      #@system_user_1.app_system_users.create!({:app_id => r1.app.id})
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
        #radio_btn_1.unselect_option
        #click_button(I18n.t("general.confirm"))
        # capybara won't let radio buttons unselected
        #visit "/system_users/#{@system_user_1.id}/update_roles"

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
      check_success_audit_log("system_user", "update", "edit_role", "portal.admin")
    end

    it '[7.4] Cancel edit role' do
      verify_grant_role(true)
      al = AuditLog.all
      expect(al.length).to eq 0
    end

    it '[7.5] Current user cannot edit role for himself (view system user)' do
      root_user = SystemUser.find_by_admin(1)
      login("#{@root_user.username}@#{@root_user.domain.name}")
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
      login("#{@root_user.username}@#{@root_user.domain.name}")
      visit '/home'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.user_management")).click
      expect(current_path).to eq(user_management_root_path)
      expect(page).to have_selector("div#inactived_system_user")
    end

    it "[13.2] Click Audit log" do
      login("#{@root_user.username}@#{@root_user.domain.name}")
      visit '/home'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.audit_log")).click
      expect(current_path).to eq(search_audit_logs_path)
    end

    it "[13.3] Select Role Management" do
      login("#{@root_user.username}@#{@root_user.domain.name}")
      visit '/home'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.role_management")).click
      expect(current_path).to eq(role_management_root_path)
    end
  end

  describe "[14] Role authorization" do
    fixtures :apps, :permissions, :role_permissions, :roles, :role_types, :licensees, :domains

    before(:each) do
      @licensee = Licensee.first
      @domain = Domain.first
    end

    it "[14.1] click unauthorized action" do
      auditor_role = Role.find_by_name "auditor"
      user_manager_role = Role.find_by_name "user_manager"

      auditor_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
      auditor_2 = create(:system_user, :roles => [auditor_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
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
      auditor_1 = create(:system_user, :roles => [auditor_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
      login("#{auditor_1.username}@#{auditor_1.domain.name}")
      visit home_root_path
      visit user_management_root_path
      verify_unauthorized_request
    end

    it "[14.3] Search audit log (authorized)" do
      auditor_role = Role.find_by_name "auditor"
      auditor_1 = create(:system_user, :roles => [auditor_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
      login("#{auditor_1.username}@#{auditor_1.domain.name}")
      visit home_root_path
      visit search_audit_logs_path
      expect(current_path).to eq search_audit_logs_path
      verify_authorized_request
    end

    it "[14.4] Search audit log (unauthorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item(I18n.t("header.audit_log"), false)
    end

    it "[14.5] List System User (authorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
    end

    it "[14.6] List System User (unauthorized)" do
      auditor_role = Role.find_by_name "auditor"
      auditor_1 = create(:system_user, :roles => [auditor_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
      login("#{auditor_1.username}@#{auditor_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item(I18n.t("header.user_management"), false)
    end

    it "[14.7] View user profile (authroized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
      user_manager_2 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
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
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
      user_manager_2 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000], :domain_id => @domain.id, :licensee_id => @licensee.id)
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

    xit "[14.9] Lock System user (authorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :domain_id => @domain.id, :licensee_id => @licensee.id)
      user_manager_2 = create(:system_user, :roles => [user_manager_role], :domain_id => @domain.id, :licensee_id => @licensee.id)
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
      click_link I18n.t("user.list_users")
      user_manager_2_profile_link_selector = "div#content table tbody tr:nth-child(2) td:first-child a"
      #find(user_manager_2_profile_link_selector).click
      click_button I18n.t("user.lock")
      verify_authorized_request
    end

    xit "[14.10] Lock System user (unauthorized)" do
      allow(SystemUserPolicy).to receive("lock?").and_return(false)
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :domain_id => @domain.id, :licensee_id => @licensee.id)
      user_manager_2 = create(:system_user, :roles => [user_manager_role], :domain_id => @domain.id, :licensee_id => @licensee.id)
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
      click_link I18n.t("user.list_users")
      user_manager_2_profile_link_selector = "div#content table tbody tr:nth-child(2) td:first-child a"
      #find(user_manager_2_profile_link_selector).click
      expect(has_link?(I18n.t("user.lock"))).to be false
    end

    xit "[14.11] Un-lock system user (authorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :domain_id => @domain.id, :licensee_id => @licensee.id)
      user_manager_2 = create(:system_user, :status => false, :roles => [user_manager_role], :domain_id => @domain.id, :licensee_id => @licensee.id)
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
      click_link I18n.t("user.list_users")
      user_manager_2_profile_link_selector = "div#content table tbody tr:nth-child(2) td:first-child a"
      #find(user_manager_2_profile_link_selector).click
      click_button I18n.t("user.unlock")
      verify_authorized_request
    end

    xit "[14.12] un-lock system user (unauthorized)" do
      allow(SystemUserPolicy).to receive("unlock?").and_return(false)
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = create(:system_user, :roles => [user_manager_role], :domain_id => @domain.id, :licensee_id => @licensee.id)
      user_manager_2 = create(:system_user, :roles => [user_manager_role], :domain_id => @domain.id, :licensee_id => @licensee.id)
      login("#{user_manager_1.username}@#{user_manager_1.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
      click_link I18n.t("user.list_users")
      user_manager_2_profile_link_selector = "div#content table tbody tr:nth-child(2) td:first-child a"
      #find(user_manager_2_profile_link_selector).click
      expect(has_link?(I18n.t("user.unlock"))).to be false
    end
  end
end 
