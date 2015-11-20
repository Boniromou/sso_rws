require "feature_spec_helper"

describe SystemUserSessionsController do
  fixtures :apps, :permissions, :role_permissions, :roles, :auth_sources

  before(:all) do
    @root_user = create(:system_user, :admin)
    create(:property, :id => 1000)
  end

  describe "[1] Login" do
    before(:each) do
      #@u1 = SystemUser.create!(:username => 'lulu', :status => true, :admin => false, :auth_source_id => 1)
      @u1 = create(:system_user)
    end

    after(:each) do
      @u1.destroy
    end

    it "[1.1] Login successful" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      visit '/login'
      fill_in "system_user_username", :with => @root_user.username
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.login")
      expect(page.current_path).to eq home_root_path
    end

    it "[1.2] login fail with wrong password" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(false)
      visit '/login'
      fill_in "system_user_username", :with => @root_user.username
      fill_in "system_user_password", :with => 'wrong'
      click_button I18n.t("general.login")
      expect(page).to have_content I18n.t("alert.invalid_login")
    end

    it "[1.3] login fail with wrong account" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      visit '/login'
      fill_in "system_user_username", :with => 'wrong_username'
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.login")
      expect(page).to have_content I18n.t("alert.invalid_login")
    end

    it "[1.6] login without role assigned" do
      visit '/login'
      fill_in "system_user_username", :with => @u1.username
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.login")
      expect(page).to have_content I18n.t("alert.account_no_role")
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
