require "feature_spec_helper"

describe ChangeLogsController do
  fixtures :apps, :permissions, :role_permissions, :roles

  before(:each) do
    @root_user = create(:system_user, :admin, :with_casino_ids => [1000])
    user_manager_role =  Role.find_by_name("user_manager")
    @system_user_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
    @system_user_2 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1003])
    @system_user_3 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1003, 1007, 1014])

    it_support_role = Role.find_by_name("it_support")
    @system_user_4 = create(:system_user, :roles => [it_support_role], :with_casino_ids => [1003, 1007])
    @system_user_5 = create(:system_user, :roles => [it_support_role], :with_casino_ids => [1000])
    create(:auth_source, :token => '192.1.1.1', :type => 'Ldap')
  end

  describe "[25] Change log for create system user", :js => true do
        
    def fill_in_user_info(username, domain)
      fill_in "system_user_username", :with => username
      select domain, :from => "system_user[domain]"
    end

    def verify_change_log_table_column_header
      col_headers = all("div#content table thead th")
      expect(col_headers.length).to eq 4
      expect(col_headers[0].text).to eq(I18n.t("change_log.user"))
      expect(col_headers[1].text).to eq(I18n.t("change_log.action"))
      expect(col_headers[2].text).to eq(I18n.t("change_log.action_at"))
      expect(col_headers[3].text).to eq(I18n.t("change_log.action_by"))
    end

    def test_click_create_btn(username)
      page.find("#modal_link").click
      wait_for_ajax
      expect(page).to have_content I18n.t("general.cancel")
      expect(page).to have_content I18n.t("general.confirm")
      expect(page).to have_content I18n.t("alert.create_system_user_confirm", :username => username)
      click_button I18n.t("general.confirm")
    end

    def test_target_casinos(system_user, cl)
      target_casinos = cl.target_casinos
      expect(target_casinos.length).to eq system_user.active_casino_ids.length
    end

    def create_system_user_change_logs(created_ats = nil)
      content = { :action_by => {:username => 'user1', :casino_ids => [1000, 1003, 1007, 1014, 20000]}, :action => "create", :type => 'SystemUserChangeLog' }
      resources = [
        [@system_user_1, 1000],
        [@system_user_2, 1000],
        [@system_user_3, 1000],
        [@system_user_4, 1003],
        [@system_user_4, 1007],
        [@system_user_5, 1014]
      ]
      resources.each_with_index do |resource, index|
        change_log = create(:change_log, content.merge(:target_username => resource[0].username))
        if created_ats
          change_log.created_at = created_ats[index]
          change_log.save!
        end
        change_log.target_casinos.create(:change_log_id => change_log.id,  :target_casino_id => resource[1])
      end
    end

    it "[25.1] No Premission for List create system user change log" do
      allow_any_instance_of(Ldap).to receive(:ldap_login!).and_return(@system_user_2)
      login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
      visit user_management_root_path
      expect(has_link?(I18n.t("user.create_system_user"))).to be false
      expect(has_link?(I18n.t("user.system_user"))).to be true
      expect(has_link?(I18n.t("general.dashboard"))).to be true
    end

    it "[25.2] List create system user change log" do
      allow_any_instance_of(Ldap).to receive(:ldap_login!).and_return(@system_user_4)
      login("#{@system_user_4.username}@#{@system_user_4.domain.name}")
      visit create_system_user_change_logs_path(:commit => true)
      verify_change_log_table_column_header
    end

    it "[25.3] Create system user change log" do
      allow_any_instance_of(Ldap).to receive(:ldap_login!).and_return(@system_user_4)
      mock_ad_account_profile
      #auth_source_detail = create(:auth_source_detail, :name => 'test_ldap', :data => {})
      #@system_user_4.domain.update_attributes(:auth_source_detail_id => auth_source_detail.id)
      login("#{@system_user_4.username}@#{@system_user_4.domain.name}")
      visit new_system_user_path
      fill_in_user_info('abc', 'example.com')
      test_click_create_btn('abc@example.com')
      cls = SystemUserChangeLog.by_action('create')
      expect(cls.length).to eq 1
      expect(cls[0].created_at).to be_kind_of(Time)
      expect(cls[0].action).to eq "create"
      expect(cls[0].target_username).to eq 'abc'
      expect(cls[0].target_domain).to eq 'example.com'
      expect(cls[0].action_by['username']).to eq "#{@system_user_4.username}@#{@system_user_4.domain.name}"
      expect(cls[0].action_by['casino_ids']).to eq @system_user_4.active_casino_ids  
      system_user = SystemUser.where(:username => 'abc').first
      test_target_casinos(system_user, cls[0])
    end

    it "[25.4] search by start/end date" do
      allow_any_instance_of(Ldap).to receive(:ldap_login!).and_return(@system_user_4)
      mock_time_at_now "2016-03-31 09:00:00"
      one_day_age = 5.day.ago
      create_system_user_change_logs([
        one_day_age,
        one_day_age,
        one_day_age,
        Time.parse("2016-03-29 15:00:00"),
        Time.now
      ])

      login("#{@system_user_4.username}@#{@system_user_4.domain.name}")
      visit create_system_user_change_logs_path(:commit => true, :start_time => "2016-03-30", :end_start => "2016-03-31")

      rc_rows = all("div#content table tbody tr")
      expect(rc_rows.length).to eq 1
    end

    it "[25.5] 1000 user show all change log" do
      allow_any_instance_of(Ldap).to receive(:ldap_login!).and_return(@system_user_5)
      create_system_user_change_logs
      login("#{@system_user_5.username}@#{@system_user_5.domain.name}")
      visit create_system_user_change_logs_path(:commit => true)
      rc_rows = all("div#content table tbody tr")
      expect(rc_rows.length).to eq 6
    end

    it "[25.6] 1003, 1007 user show target user casino 1003 and 1007 change log" do
      allow_any_instance_of(Ldap).to receive(:ldap_login!).and_return(@system_user_4)
      mock_ad_account_profile('active', [1003, 1007])
      create_system_user_change_logs
      login("#{@system_user_4.username}@#{@system_user_4.domain.name}")
      visit create_system_user_change_logs_path(:commit => true)
      rc_rows = all("div#content table tbody tr")
      expect(rc_rows.length).to eq 2
    end
  end
end
