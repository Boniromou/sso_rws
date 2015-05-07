require "feature_spec_helper"

describe SystemUsersController do
  fixtures :apps, :permissions, :role_permissions, :roles

  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = SystemUser.find_by_admin(1) || SystemUser.create(:id => 1, :username => "portal.admin", :status => true, :admin => true, :auth_source_id => 1)
  end

  after(:all) do
    Warden.test_reset! 
  end
  
  describe "[4] List System user" do
    before(:each) do
      
    end

    after(:each) do
    end

    it "[4.1] verify the list system user" do
      login_as(@root_user, :scope => :system_user)
      visit '/system_users'
      expect(page).to have_selector('table tr', :count => 1)
      expect(page).to have_content(I18n.t("user.user_name"))
      expect(page).to have_content(I18n.t("user.status"))
      expect(page).to have_content(I18n.t("general.operation"))
      logout(@root_user)
    end
  end

  describe '[5] View system user' do
    before(:each) do
      @system_user_1 = SystemUser.create!(:username => "lulupdan", :status => true, :admin => false)
      user_manager_role = Role.find_by_name "user_manager"
      @system_user_1.update_roles([user_manager_role.id])
    end

    after(:each) do
      RoleAssignment.delete_all
      AppSystemUser.delete_all
      @system_user_1.destroy
    end

    it '[5.1] Check Single user content' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@root_user.id}"
      expect(page).to have_content(@root_user.username)
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_content(I18n.t("role.role"))
      #expect(page).to have_content(I18n.t("role.root_user"))
      logout(@root_user)
    end

    it '[5.2] Current user cannot edit role for himself' do
      login_as(@system_user_1, :scope => :system_user)
      visit "/system_users/#{@system_user_1.id}"
      expect(page).to have_content(@system_user_1.username)
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_content(I18n.t("role.role"))
      #expect(page).to have_content(I18n.t("role.root_user"))
      expect(page).to have_no_button(I18n.t("general.edit"))
      logout(@system_user_1)
    end

    it '[5.3] Edit button is alwawys disabled in Root user' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@root_user.id}"
      expect(page).to have_content(@root_user.username)
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_content(I18n.t("role.role"))
      #expect(page).to have_content(I18n.t("general.na")) 
      expect(page).to have_no_button(I18n.t("general.edit"))
      logout(@root_user)
    end
  end

  describe "[6] Activate/De-activate system user" do
    before(:each) do
      @auth_source = AuthSource.find_by_name('Laxino LDAP MO')
      @system_user_1 = SystemUser.create!(:username => "lulupdan", :status => true, :admin => false)
      @system_user_2 = SystemUser.create!(:username => "lalalala", :status => false, :admin => false, :auth_source_id => @auth_source.id)
 #     @system_user_3 = SystemUser.create!(:username => "gogopanda", :status => false, :admin => false)
      AuditLog.delete_all 
    end

    after(:each) do
      @system_user_1.destroy
      @system_user_2.destroy
#      @system_user_3.destroy
      AuditLog.delete_all
    end

    it "[6.1] Activate system user (list system user)" do
      login_as(@root_user, :scope => :system_user)
      visit '/system_users'
      expect(page.all('tr')[2].all('td')[0]).to have_content(@system_user_2.username)
      expect(page.all('tr')[2].all('td')[1]).to have_content(I18n.t("user.inactive"))
      expect(page.all('tr')[2].all('td')[2]).to have_button(I18n.t("user.unlock"))
      click_button I18n.t("user.unlock")
      expect(page.all('tr')[2].all('td')[0]).to have_content(@system_user_2.username)
      expect(page.all('tr')[2].all('td')[1]).to have_content(I18n.t("user.active"))
      expect(page.all('tr')[2].all('td')[2]).to have_button(I18n.t("user.lock"))
      check_flash_message I18n.t("success.unlock_user", :user_name => @system_user_2.username)
    end

    it "[6.2] De-activate system user (list system user)" do
      login_as(@root_user, :scope => :system_user)
      visit '/system_users'
      expect(page.all('tr')[1].all('td')[0]).to have_content(@system_user_1.username)
      expect(page.all('tr')[1].all('td')[1]).to have_content(I18n.t("user.active"))
      expect(page.all('tr')[1].all('td')[2]).to have_button(I18n.t("user.lock"))
      click_button I18n.t("user.lock")
      expect(page.all('tr')[1].all('td')[0]).to have_content(@system_user_1.username)
      expect(page.all('tr')[1].all('td')[1]).to have_content(I18n.t("user.inactive"))
      expect(page.all('tr')[1].all('td')[2]).to have_button(I18n.t("user.unlock"))
      check_flash_message I18n.t("success.lock_user", :user_name => @system_user_1.username)
    end
=begin
    it "[6.3] Activate system user (view system user)" do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@system_user_2.id}"
      expect(page).to have_content(@system_user_2.username)
      expect(page).to have_content(I18n.t("user.inactive"))
      click_button I18n.t("user.unlock")
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_button(I18n.t("user.lock"))
    end

    it "[6.4] de-Activate system user (view system user)" do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@system_user_1.id}"
      expect(page).to have_content(@system_user_1.username)
      expect(page).to have_content(I18n.t("user.active"))
      click_button I18n.t("user.lock")
      expect(page).to have_content(I18n.t("user.inactive"))
      expect(page).to have_button(I18n.t("user.unlock"))
    end
=end
    it '[6.5] login as de-activated account' do
      visit "/"
      fill_in "system_user_username", :with => @system_user_2.username
      fill_in "system_user_password", :with => "1233444"
      click_button I18n.t("general.login")
      expect(page).to have_content I18n.t("alert.inactive_account")
    end

    it "[6.6] Current user cannot de-activate himself (list system user)" do
      login_as(@root_user, :scope => :system_user)
      visit '/system_users'
      expect(page.all('tr')[0].all('td')[0]).to have_content(@root_user.username)
      expect(page.all('tr')[0].all('td')[1]).to have_content(I18n.t("user.active"))
      expect(page.all('tr')[0].all('td')[2]).to have_no_button(I18n.t("user.lock"))
    end
=begin
    it "[6.7] Current user cannot de-activate himself (view system user)" do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@root_user.id}"
      expect(page).to have_content(@root_user.username)
      expect(page).to have_content(I18n.t("user.status"))
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_no_button(I18n.t("user.lock"))
      expect(page).to have_content(I18n.t("role.role"))
      #expect(page).to have_content(I18n.t("role.root_user"))
      expect(page).to have_no_button(I18n.t("general.edit"))
      logout(@root_user) 
    end
=end
    it '[6.8] audit log for Activate system user' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users"
      expect(page.all('tr')[2].all('td')[0]).to have_content(@system_user_2.username)
      expect(page.all('tr')[2].all('td')[1]).to have_content(I18n.t("user.inactive"))
      expect(page.all('tr')[2].all('td')[2]).to have_button(I18n.t("user.unlock"))
      click_button I18n.t("user.unlock")
      al = AuditLog.first
      expect(al.audit_target).to eq("system_user")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("unlock")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[6.9] audit log for De-activate system user' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users"
      expect(page.all('tr')[1].all('td')[0]).to have_content(@system_user_1.username)
      expect(page.all('tr')[1].all('td')[1]).to have_content(I18n.t("user.active"))
      expect(page.all('tr')[1].all('td')[2]).to have_button(I18n.t("user.lock"))
      click_button I18n.t("user.lock")
      al = AuditLog.first
      expect(al.audit_target).to eq("system_user")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("lock")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[6.10] De-activate an active user' do
      system_user = SystemUser.create!(:username => "tester", :status => true, :admin => false)
      login_as(system_user, :scope => :system_user)
      system_user.status = false
      system_user.save
      visit home_root_path
      #expect(page.status_code).to eq 401
      #visit '/dashboard'
      expect(page).to have_content I18n.t("alert.inactive_account")
    end
  end

  describe '[7] Edit Roles' do
    before(:each) do
      @system_user_1 = SystemUser.create!(:username => "ray1", :status => true, :admin => false)
      @system_user_2 = SystemUser.create!(:username => "ray2", :status => true, :admin => false)
      #@user_manager = Role.first
      #@helpdesk = Role.find_by_name("helpdesk")
      #@system_user_2.role_assignments.create!({:role_id => @helpdesk.id})
    end

    after(:each) do
      RoleAssignment.delete_all
      AppSystemUser.delete_all
      AuditLog.delete_all
      @system_user_1.destroy
      @system_user_2.destroy
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
        visit "/system_users/#{@system_user_1.id}/update_roles"
      end
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
      login_as(@root_user)
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
      login_as(@root_user)
      visit '/home'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.role_management")).click
      expect(current_path).to eq(role_management_root_path)
    end
  end

  describe "[14] Role authorization" do
    fixtures :apps, :permissions, :role_permissions, :roles

    before(:each) do
      AppSystemUser.delete_all
      SystemUser.delete_all
    end

    after(:each) do
      AppSystemUser.delete_all
      SystemUser.delete_all
    end

    after(:all) do
      RolePermission.delete_all
      Role.delete_all
      Permission.delete_all
      AppSystemUser.delete_all
      SystemUser.delete_all
      App.delete_all
    end

    it "[14.1] click unauthorized action" do
      auditor_role = Role.find_by_name "auditor"
      user_manager_role = Role.find_by_name "user_manager"
      auditor_1 = SystemUser.create!(:username => "auditor_1", :status => true, :admin => false)
      auditor_2 = SystemUser.create!(:username => "auditor_2", :status => true, :admin => false)
      auditor_1.update_roles([user_manager_role.id])
      auditor_2.update_roles([auditor_role.id])
      login_as(auditor_1, :scope => :system_user)
      visit home_root_path
      visit system_users_path
      auditor_1.update_roles([auditor_role.id])
      lock_usr_btn_select = "div#content table tbody tr:nth-child(2) td:nth-child(3) input"
      find(lock_usr_btn_select).click
      verify_unauthorized_request
    end

    it "[14.2] click link to the unauthorized page" do
      auditor_role = Role.find_by_name "auditor"
      auditor_1 = SystemUser.create!(:username => "auditor_1", :status => true, :admin => false)
      auditor_1.update_roles([auditor_role.id])
      login_as(auditor_1, :scope => :system_user)
      visit home_root_path
      visit user_management_root_path
      verify_unauthorized_request
    end

    it "[14.3] Search audit log (authorized)" do
      auditor_role = Role.find_by_name "auditor"
      auditor_1 = SystemUser.create!(:username => "auditor_1", :status => true, :admin => false)
      auditor_1.update_roles([auditor_role.id])
      login_as(auditor_1, :scope => :system_user)
      visit home_root_path
      visit search_audit_logs_path
      expect(current_path).to eq search_audit_logs_path
      verify_authorized_request
    end

    it "[14.4] Search audit log (unauthorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = SystemUser.create!(:username => "user_manager_1", :status => true, :admin => false)
      user_manager_1.update_roles([user_manager_role.id])
      login_as(user_manager_1, :scope => :system_user)
      visit home_root_path
      assert_dropdown_menu_item(I18n.t("header.audit_log"), false)
    end

    it "[14.5] List System User (authorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = SystemUser.create!(:username => "user_manager_1", :status => true, :admin => false)
      user_manager_1.update_roles([user_manager_role.id])
      login_as(user_manager_1, :scope => :system_user)
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
    end

    it "[14.6] List System User (unauthorized)" do
      auditor_role = Role.find_by_name "auditor"
      auditor_1 = SystemUser.create!(:username => "auditor_1", :status => true, :admin => false)
      auditor_1.update_roles([auditor_role.id])
      login_as(auditor_1, :scope => :system_user)
      visit home_root_path
      assert_dropdown_menu_item(I18n.t("header.user_management"), false)
    end

    it "[14.7] View user profile (authroized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = SystemUser.create!(:username => "user_manager_1", :status => true, :admin => false)
      user_manager_2 = SystemUser.create!(:username => "user_manager_2", :status => true, :admin => false)
      user_manager_1.update_roles([user_manager_role.id])
      user_manager_2.update_roles([user_manager_role.id])
      login_as(user_manager_1, :scope => :system_user)
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
      user_manager_1 = SystemUser.create!(:username => "user_manager_1", :status => true, :admin => false)
      user_manager_2 = SystemUser.create!(:username => "user_manager_2", :status => true, :admin => false)
      user_manager_1.update_roles([user_manager_role.id])
      user_manager_2.update_roles([user_manager_role.id])
      login_as(user_manager_1, :scope => :system_user)
      visit home_root_path
      assert_dropdown_menu_item I18n.t("header.user_management")
      visit user_management_root_path
      assert_left_panel_item I18n.t("general.dashboard")
      assert_left_panel_item I18n.t("user.list_users")
      click_link I18n.t("user.list_users")
      user_manager_2_profile_link_selector = "div#content table tbody tr:nth-child(2) td:first-child a"
      find(user_manager_2_profile_link_selector).click
      click_button I18n.t("general.edit")
      expect(has_link?(I18n.t("general.cancel"))).to be true
      click_button I18n.t("general.confirm")
      verify_authorized_request
    end

    it "[14.9] Lock System user (authorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = SystemUser.create!(:username => "user_manager_1", :status => true, :admin => false)
      user_manager_2 = SystemUser.create!(:username => "user_manager_2", :status => true, :admin => false)
      user_manager_1.update_roles([user_manager_role.id])
      user_manager_2.update_roles([user_manager_role.id])
      login_as(user_manager_1, :scope => :system_user)
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

    it "[14.10] Lock System user (unauthorized)" do
      allow(SystemUserPolicy).to receive("lock?").and_return(false)
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = SystemUser.create!(:username => "user_manager_1", :status => true, :admin => false)
      user_manager_2 = SystemUser.create!(:username => "user_manager_2", :status => true, :admin => false)
      user_manager_1.update_roles([user_manager_role.id])
      user_manager_2.update_roles([user_manager_role.id])
      login_as(user_manager_1, :scope => :system_user)
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

    it "[14.11] Un-lock system user (authorized)" do
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = SystemUser.create!(:username => "user_manager_1", :status => true, :admin => false)
      user_manager_2 = SystemUser.create!(:username => "user_manager_2", :status => false, :admin => false)
      user_manager_1.update_roles([user_manager_role.id])
      user_manager_2.update_roles([user_manager_role.id])
      login_as(user_manager_1, :scope => :system_user)
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

    it "[14.12] un-lock system user (unauthorized)" do
      allow(SystemUserPolicy).to receive("unlock?").and_return(false)
      user_manager_role = Role.find_by_name "user_manager"
      user_manager_1 = SystemUser.create!(:username => "user_manager_1", :status => true, :admin => false)
      user_manager_2 = SystemUser.create!(:username => "user_manager_2", :status => true, :admin => false)
      user_manager_1.update_roles([user_manager_role.id])
      user_manager_2.update_roles([user_manager_role.id])
      login_as(user_manager_1, :scope => :system_user)
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
