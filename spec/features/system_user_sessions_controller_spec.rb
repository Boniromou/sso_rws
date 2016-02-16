require "feature_spec_helper"

describe SystemUserSessionsController do
  fixtures :apps, :permissions, :role_permissions, :roles, :auth_sources

  before(:each) do
    @root_user = create(:system_user, :admin, :with_property_ids => [1000])
    #create(:property, :id => 1000)
  end

  describe "[1] Login" do
    before(:each) do
      #@u1 = SystemUser.create!(:username => 'lulu', :status => true, :admin => false, :auth_source_id => 1)
      @u1 = create(:system_user)
      user_manager_role = Role.find_by_name "user_manager"
      @system_user_1 = create(:system_user, :roles => [user_manager_role], :with_property_ids => [1003, 1007])
    end

    def go_login_page_and_login(username)
      visit login_path
      fill_in "system_user_username", :with => username
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.login")
    end

    it "[1.1] Login successful" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      go_login_page_and_login("#{@root_user.username}@#{@root_user.domain}")
      expect(page.current_path).to eq home_root_path
    end

    it "[1.2] login fail with wrong password" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(false)
      go_login_page_and_login("#{@root_user.username}@#{@root_user.domain}")
      expect(page).to have_content I18n.t("alert.invalid_login")
    end

    it "[1.3] login fail with wrong account" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      go_login_page_and_login('wrong_username')
      expect(page).to have_content I18n.t("alert.invalid_login")
    end

    it "[1.6] login without role assigned" do
      go_login_page_and_login("#{@u1.username}@#{@u1.domain}")
      expect(page).to have_content I18n.t("alert.account_no_role")
    end

    it "[1.9] Login successful and update the User property group" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      mock_ad_account_profile(true, [1003])
      go_login_page_and_login("#{@system_user_1.username}@#{@system_user_1.domain}")
      property_system_user_1003 = PropertiesSystemUser.where(:property_id => 1003, :system_user_id => @system_user_1.id).first
      property_system_user_1007 = PropertiesSystemUser.where(:property_id => 1007, :system_user_id => @system_user_1.id).first
      expect(property_system_user_1003.status).to eq true
      expect(property_system_user_1007.status).to eq false
      expect(page.current_path).to eq home_root_path
    end

    it "[1.10] Login fail with user AD property group null" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      mock_ad_account_profile(true, [])
      go_login_page_and_login("#{@system_user_1.username}@#{@system_user_1.domain}")
      property_system_user_1003 = PropertiesSystemUser.where(:property_id => 1003, :system_user_id => @system_user_1.id).first
      property_system_user_1007 = PropertiesSystemUser.where(:property_id => 1007, :system_user_id => @system_user_1.id).first
      expect(property_system_user_1003.status).to eq false
      expect(property_system_user_1007.status).to eq false
      expect(page).to have_content I18n.t("alert.account_no_property")
    end

    it "[1.11] Login successful and update the User lock/unlock status" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      mock_ad_account_profile(false, [])
      go_login_page_and_login("#{@system_user_1.username}@#{@system_user_1.domain}")
      @system_user_1.reload
      expect(@system_user_1.status).to eq false
      expect(page).to have_content I18n.t("alert.inactive_account")
    end

    it "[1.12] login user with upper case" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      go_login_page_and_login("#{@system_user_1.username}@#{@system_user_1.domain}".upcase)
      expect(page.current_path).to eq home_root_path
      expect(AppSystemUser.first.system_user_id).to eq @system_user_1.id
    end

    it "login user with role permission value" do
      @system_user_1.roles[0].role_permissions.each do |rp|
        rp.value = 1
        rp.save
      end
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      go_login_page_and_login("#{@system_user_1.username}@#{@system_user_1.domain}")
      expect(page.current_path).to eq home_root_path
      cache_key = "#{APP_NAME}:permissions:#{@system_user_1.id}"
      permissions = Rails.cache.fetch cache_key
      expect(permissions[:permissions][:values]).to_not eq nil
      @system_user_1.roles[0].role_permissions.each do |rp|
        expect(permissions[:permissions][:values][rp.permission.target.to_sym][rp.permission.action.to_sym]).to eq "1"
      end
    end

  end

  describe "[1] Logout" do
    it "[1.4] Logout successful" do
      login_as(@root_user, :scope => :system_user)
      visit '/dashboard/home'
      click_link I18n.t("general.logout")
      expect(page.current_path).to eq root_path
    end
  end
end
