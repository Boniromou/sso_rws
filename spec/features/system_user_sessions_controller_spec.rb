require "feature_spec_helper"

describe SystemUserSessionsController do
  fixtures :apps, :permissions, :role_permissions, :roles, :auth_sources

  before(:each) do
    mock_ad_account_profile
    @root_user = create(:system_user, :admin, :with_casino_ids => [1000])
  end

  describe "[1] Login" do
    def create_change_logs_without_target_casinos(user)
      actions = ['create', 'edit_role']
      content = { :action_by => {:username => 'user1', :casino_ids => [1000]}, :type => 'SystemUserChangeLog', :target_username => "#{user.username}", :target_domain => "#{user.domain.name}"}
      actions.each do |action|
        change_log = create(:change_log, content.merge(:action => action))
      end
    end

    def check_target_casinos(action, casino_ids)
      cl = ChangeLog.find_by_action(action)
      target_casinos = TargetCasino.where(change_log_id: cl.id)
      expect(target_casinos.size).to eq casino_ids.size
      target_casinos.each_with_index do |target_casino, index|
        expect(target_casino['change_log_id']).to eq cl.id
        expect(target_casino['target_casino_id']).to eq casino_ids[index]
      end
    end

    before(:each) do
      @u1 = create(:system_user)
      user_manager_role = Role.find_by_name "user_manager"
      @system_user_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1003, 1007])
    end

    it "[1.1] Login successful" do
      count = LoginHistory.count
      login("#{@root_user.username}@#{@root_user.domain.name}")
      expect(page.current_path).to eq home_root_path
      expect(LoginHistory.count).to eq count + 1
      login_history = LoginHistory.last
      expect(login_history.system_user_id).to eq @root_user.id
      expect(login_history.domain_id).to eq @root_user.domain.id
      expect(login_history.app_id).to eq App.find_by_name(APP_NAME).id
      detail = {}
      detail['casino_ids'] = [1000]
      detail['casino_id_names'] = [{'id' => 1000, 'name' => Casino.find(1000).name}]
      expect(login_history.detail).to eq detail
    end

    it "[1.2] login fail with wrong password" do
      mock_authenticate_failed
      login("#{@root_user.username}@#{@root_user.domain.name}")
      expect_have_content(I18n.t("alert.invalid_login").titleize)
    end

    it "[1.3] login fail with wrong account" do
      login("abc")
      expect_have_content(I18n.t("alert.invalid_login").titleize)
    end

    it "[1.6] login without role assigned" do
      login("#{@u1.username}@#{@u1.domain.name}")
      expect_have_content(I18n.t("alert.account_no_role").chomp('.').titleize)
    end

    it "[1.9] Login successful and update the User casino group" do
      mock_ad_account_profile('active', [1003])
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      casino_system_user_1003 = CasinosSystemUser.where(:casino_id => 1003, :system_user_id => @system_user_1.id).first
      casino_system_user_1007 = CasinosSystemUser.where(:casino_id => 1007, :system_user_id => @system_user_1.id).first
      expect(casino_system_user_1003.status).to eq true
      expect(casino_system_user_1007.status).to eq false
      expect(page.current_path).to eq home_root_path
    end

    it "[1.10] Login fail with user AD casino group null" do
      mock_ad_account_profile('active', [])
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      casino_system_user_1003 = CasinosSystemUser.where(:casino_id => 1003, :system_user_id => @system_user_1.id).first
      casino_system_user_1007 = CasinosSystemUser.where(:casino_id => 1007, :system_user_id => @system_user_1.id).first
      expect(casino_system_user_1003.status).to eq false
      expect(casino_system_user_1007.status).to eq false
      expect_have_content(I18n.t("alert.account_no_casino").titleize)
    end

    it "[1.11] Login successful and update the User status" do
      mock_ad_account_profile('inactive', [])
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      @system_user_1.reload
      expect(@system_user_1.status).to eq 'inactive'
      expect_have_content(I18n.t("alert.inactive_account").chomp('.').titleize)
    end

    it "[1.12] login user with upper case" do
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      expect(page.current_path).to eq home_root_path
      expect(AppSystemUser.first.system_user_id).to eq @system_user_1.id
    end

    it '[1.13] Login fail with AD casino not match with local' do
      mock_ad_account_profile('active', [rand(9999)])
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      expect_have_content(I18n.t("alert.account_no_casino").titleize)
    end

    it '[1.15] Login fail with auth_source - domain mapping not exist' do
      domain = @u1.domain
      domain.auth_source_detail_id = nil
      domain.save!
      login("#{@u1.username}@#{@u1.domain.name}")
      expect_have_content_downcase(I18n.t("alert.invalid_ldap_mapping"), '.')
    end

    it "login user with role permission value" do
      @system_user_1.roles[0].role_permissions.each do |rp|
        rp.value = "1"
        rp.save
      end
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      expect(page.current_path).to eq home_root_path
      cache_key = "#{APP_NAME}:permissions:#{@system_user_1.id}"
      permissions = Rails.cache.fetch cache_key
      expect(permissions[:permissions][:values]).to_not eq nil
      @system_user_1.roles[0].role_permissions.each do |rp|
        expect(permissions[:permissions][:values][rp.permission.target.to_sym][rp.permission.action.to_sym]).to eq "1"
        expect(@system_user_1.roles[0].get_permission_value(rp.permission.target, rp.permission.action)).to eq "1"
      end
    end

    it "login successful with user status = pending" do
      create_change_logs_without_target_casinos(@system_user_1)
      expect(TargetCasino.all.size).to eq 0
      @system_user_1.update_attributes!(status: SystemUser::PENDING)
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      expect(page.current_path).to eq home_root_path
      @system_user_1.reload
      expect(@system_user_1.status).to eq SystemUser::ACTIVE
      check_target_casinos('create', @system_user_1.active_casino_ids)
      check_target_casinos('edit_role', @system_user_1.active_casino_ids)
    end
  end

  describe "[1] Logout" do
    it "[1.4] Logout successful" do
      login_as(@root_user, :scope => :system_user)
      visit '/dashboard/home'
      click_link I18n.t("general.logout")
      expect(page.current_path).to eq ldap_new_path
    end
  end
end
