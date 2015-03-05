require "feature_spec_helper"

describe SystemUsersController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = SystemUser.find_by_admin(1)
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
    end

    after(:each) do
      @system_user_1.destroy
    end

    it '[5.1] Check Single user content' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@root_user.id}"
      expect(page).to have_content(@root_user.username)
      expect(page).to have_content(I18n.t("user.status"))
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_content(I18n.t("role.role"))
      expect(page).to have_content(I18n.t("role.root_user"))
      logout(@root_user)
    end

    it '[5.2] Current user cannot edit role for himself' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@root_user.id}"
      expect(page).to have_content(@root_user.username)
      expect(page).to have_content(I18n.t("user.status"))
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_content(I18n.t("role.role"))
      expect(page).to have_content(I18n.t("role.root_user"))
      expect(page).to have_no_button(I18n.t("general.edit"))
      logout(@root_user)
    end

    it '[5.3] Edit button is alwawys disabled in Root user' do
      login_as(@system_user_1, :scope => :system_user)
      visit "/system_users/#{@system_user_1.id}"
      expect(page).to have_content(@system_user_1.username)
      expect(page).to have_content(I18n.t("user.status"))
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_content(I18n.t("role.role"))
      expect(page).to have_content(I18n.t("general.na")) 
      expect(page).to have_no_button(I18n.t("general.edit"))
      logout(@system_user_1)
    end
  end

  describe "[6] Activate/De-activate system user" do
    before(:each) do
      @auth_source = AuthSource.find_by_name('Laxino LDAP')
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
    end

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

    it "[6.7] Current user cannot de-activate himself (view system user)" do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@root_user.id}"
      expect(page).to have_content(@root_user.username)
      expect(page).to have_content(I18n.t("user.status"))
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_no_button(I18n.t("user.lock"))
      expect(page).to have_content(I18n.t("role.role"))
      expect(page).to have_content(I18n.t("role.root_user"))
      expect(page).to have_no_button(I18n.t("general.edit"))
      logout(@root_user) 
    end

    it '[6.8] audit log for Activate system user' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@system_user_2.id}"
      expect(page).to have_content(@system_user_2.username)
      expect(page).to have_content(I18n.t("user.inactive"))
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
      visit "/system_users/#{@system_user_1.id}"
      expect(page).to have_content(@system_user_1.username)
      expect(page).to have_content(I18n.t("user.active"))
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
      visit '/dashboard'
      #expect(page.status_code).to eq 401
      #visit '/dashboard'
      expect(page).to have_content I18n.t("alert.unauthenticated")
    end
  end

  describe '[7] Edit Roles' do
    before(:each) do
      @system_user_1 = SystemUser.create!(:username => "lulupdan", :status => true, :admin => false)
      @system_user_2 = SystemUser.create!(:username => "lucy", :status => true, :admin => false)
      @user_manager = Role.find_by_name("user_manager")
      @helpdesk = Role.find_by_name("helpdesk")
      @system_user_2.role_assignments.create!({:role_id => @helpdesk.id})
    end

    after(:each) do
      @system_user_1.destroy
      @system_user_2.destroy
      RoleAssignment.delete_all
    end

    it '[7.1] Grant role' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@system_user_1.id}/edit_roles"
      expect(page).to have_content(@system_user_1.username)
      expect(page).to have_content(I18n.t("role.user_manager"))
      expect(page).to have_content(I18n.t("role.system_operator"))
      expect(page).to have_content(I18n.t("role.property_operator"))
      expect(page).to have_content(I18n.t("role.helpdesk"))
      expect(page).to have_content(I18n.t("role.auditor"))
      expect(page).to have_content(I18n.t("general.na"))
      find_field('roles_1', checked:false)
      find_field('roles_2', checked:false)
      find_field('roles_3', checked:false)
      find_field('roles_4', checked:false)
      find_field('roles_5', checked:false)
      find_field('roles_-1', checked:true)
      choose("roles_#{@user_manager.id}")
      find_field('roles_1', checked:true)
      find_field('roles_2', checked:false)
      find_field('roles_3', checked:false)
      find_field('roles_4', checked:false)
      find_field('roles_5', checked:false)
      find_field('roles_-1', checked:false)
      click_button(I18n.t("general.confirm"))
      expect(page).to have_content(@system_user_1.username)
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_button(I18n.t("user.lock"))
      expect(page).to have_content('Role')
      expect(page).to have_content(I18n.t("role.user_manager"))
    end

    it '[7.2] revoke role' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@system_user_2.id}/edit_roles"
      expect(page).to have_content(@system_user_2.username)
      expect(page).to have_content(I18n.t("role.user_manager"))
      expect(page).to have_content(I18n.t("role.system_operator"))
      expect(page).to have_content(I18n.t("role.property_operator"))
      expect(page).to have_content(I18n.t("role.helpdesk"))
      expect(page).to have_content(I18n.t("role.auditor"))
      expect(page).to have_content(I18n.t("general.na"))
      find_field('roles_1', checked:false)
      find_field('roles_2', checked:false)
      find_field('roles_3', checked:true)
      find_field('roles_4', checked:false)
      find_field('roles_5', checked:false)
      find_field('roles_-1', checked:false)
      choose("roles_-1")
      find_field('roles_1', checked:false)
      find_field('roles_2', checked:false)
      find_field('roles_3', checked:false)
      find_field('roles_4', checked:false)
      find_field('roles_5', checked:false)
      find_field('roles_-1', checked:true)
      click_button(I18n.t("general.confirm"))
      expect(page).to have_content(@system_user_2.username)
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_button(I18n.t("user.lock"))
      expect(page).to have_content('Role')
      expect(page).to have_content(I18n.t("general.na"))
    end

    it '[7.3] Audit edit role' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@system_user_2.id}/edit_roles"
      find_field('roles_1', checked:false)
      find_field('roles_2', checked:false)
      find_field('roles_3', checked:true)
      find_field('roles_4', checked:false)
      find_field('roles_5', checked:false)
      find_field('roles_-1', checked:false)
      choose("roles_-1")
      click_button(I18n.t("general.confirm"))
      al = AuditLog.first
      expect(al.audit_target).to eq("system_user")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("edit_role")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[7.4] Cancel edit role' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@system_user_2.id}/edit_roles"
      find_field('roles_1', checked:false)
      find_field('roles_2', checked:false)
      find_field('roles_3', checked:true)
      find_field('roles_4', checked:false)
      find_field('roles_5', checked:false)
      find_field('roles_-1', checked:false)
      choose("roles_-1")
      click_link(I18n.t("general.cancel"))
      expect(current_path).to eq(system_user_path(@system_user_2))
      expect(AuditLog.all).to be_empty
    end

    it '[7.5] Current user cannot edit role for himself (view system user)' do
      login_as(@root_user, :scope => :system_user)
      visit "/system_users/#{@root_user.id}"
      expect(page).to have_content(@root_user.username)
      expect(page).to have_content(I18n.t("user.status"))
      expect(page).to have_content(I18n.t("user.active"))
      expect(page).to have_no_button(I18n.t("user.lock"))
      expect(page).to have_content(I18n.t("role.role"))
      expect(page).to have_content(I18n.t("role.root_user"))
      expect(page).to have_no_button(I18n.t("general.edit"))
      logout(@root_user)  
    end
  end
end
