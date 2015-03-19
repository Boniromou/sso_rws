require "feature_spec_helper"

describe SystemUserSessionsController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = SystemUser.find_by_admin(1)
  end

  after(:all) do
    Warden.test_reset! 
  end

  describe "[1] Login" do
    before(:each) do
      @u1 = SystemUser.create!(:username => 'lulu', :status => true, :admin => false, :auth_source_id => 1)
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
      expect(page.current_path).to eq home_dashboard_index_path
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

    it "[1.5] login without role assigned" do
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
