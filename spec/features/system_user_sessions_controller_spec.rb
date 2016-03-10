require "feature_spec_helper"

describe SystemUserSessionsController do
  fixtures :apps, :permissions, :role_permissions, :roles, :auth_sources

  before(:each) do
    mock_authenticate
    @root_user = create(:system_user, :admin, :with_casino_ids => [1000])
  end

  describe "[1] Login" do
    before(:each) do
      #@u1 = SystemUser.create!(:username => 'lulu', :status => true, :admin => false, :auth_source_id => 1)
      @u1 = create(:system_user)
      user_manager_role = Role.find_by_name "user_manager"
      @system_user_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1003, 1007])
    end

    def go_login_page_and_login(user)
      username = 'wrong_username'
      domain = 'wrong.domain.com'
      if user.present?
        username = user.username
        domain = user.domain.name
      end
      visit login_path
      fill_in 'system_user_username', :with => "#{username}@#{domain}"
      fill_in 'system_user_password', :with => 'secret'
      click_button I18n.t("general.login")
    end

    it "[1.1] Login successful" do
      go_login_page_and_login(@root_user)
      expect(page.current_path).to eq home_root_path
    end

    it "[1.2] login fail with wrong password" do
      mock_authenticate(false)
      go_login_page_and_login(@root_user)
      expect_have_content(I18n.t("alert.invalid_login"))
    end

    it "[1.3] login fail with wrong account" do
      go_login_page_and_login(nil)
      expect_have_content(I18n.t("alert.invalid_login"))
    end

    it "[1.6] login without role assigned" do
      go_login_page_and_login(@u1)
      expect_have_content(I18n.t("alert.account_no_role"))
    end

    it "[1.9] Login successful and update the User casino group" do
      mock_ad_account_profile(true, [1003])
      go_login_page_and_login(@system_user_1)
      casino_system_user_1003 = CasinosSystemUser.where(:casino_id => 1003, :system_user_id => @system_user_1.id).first
      casino_system_user_1007 = CasinosSystemUser.where(:casino_id => 1007, :system_user_id => @system_user_1.id).first
      expect(casino_system_user_1003.status).to eq true
      expect(casino_system_user_1007.status).to eq false
      expect(page.current_path).to eq home_root_path
    end

    it "[1.10] Login fail with user AD casino group null" do
      mock_ad_account_profile(true, [])
      go_login_page_and_login(@system_user_1)
      casino_system_user_1003 = CasinosSystemUser.where(:casino_id => 1003, :system_user_id => @system_user_1.id).first
      casino_system_user_1007 = CasinosSystemUser.where(:casino_id => 1007, :system_user_id => @system_user_1.id).first
      expect(casino_system_user_1003.status).to eq false
      expect(casino_system_user_1007.status).to eq false
      expect_have_content(I18n.t("alert.account_no_casino"))
    end

    it "[1.11] Login successful and update the User lock/unlock status" do
      mock_ad_account_profile(false, [])
      go_login_page_and_login(@system_user_1)
      @system_user_1.reload
      expect(@system_user_1.status).to eq false
      expect_have_content(I18n.t("alert.inactive_account"))
    end

    it "[1.12] login user with upper case" do
      go_login_page_and_login(@system_user_1)
      expect(page.current_path).to eq home_root_path
      expect(AppSystemUser.first.system_user_id).to eq @system_user_1.id
    end

    it '[1.13] Login fail with AD casino not match with local' do
      mock_ad_account_profile(true, [rand(9999)])
      go_login_page_and_login(@system_user_1)
      expect_have_content(I18n.t("alert.account_no_casino"))
    end

    it "login user with role permission value" do
      @system_user_1.roles[0].role_permissions.each do |rp|
        rp.value = 1
        rp.save
      end
      go_login_page_and_login(@system_user_1)
      expect(page.current_path).to eq home_root_path
      cache_key = "#{APP_NAME}:permissions:#{@system_user_1.id}"
      permissions = Rails.cache.fetch cache_key
      expect(permissions[:permissions][:values]).to_not eq nil
      @system_user_1.roles[0].role_permissions.each do |rp|
        expect(permissions[:permissions][:values][rp.permission.target.to_sym][rp.permission.action.to_sym]).to eq "1"
        expect(@system_user_1.roles[0].get_permission_value(rp.permission.target, rp.permission.action)).to eq 1
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
