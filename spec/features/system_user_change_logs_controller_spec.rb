require "feature_spec_helper"

describe ChangeLogsController do

  before(:each) do
    @app_1 = App.find_by_name("user_management") || create(:app, :id => 1, :name => "user_management")
    perm_1 = create(:permission, :name => "show", :action => "show", :target => "system_user", :app => @app_1)
    perm_2 = create(:permission, :name => "grant_roles", :action => "grant_roles", :target => "system_user", :app => @app_1)
    perm_3 = create(:permission, :name => "list_edit_role_change_log", :action => "list_edit_role_change_log", :target => "system_user", :app => @app_1)
    int_role_type = create(:role_type, :name => 'internal')
    ext_role_type = create(:role_type, :name => 'external')
    @int_role_1 = create(:role, :name => "int_role_a", :with_permissions => [perm_1, perm_2, perm_3], :role_type => int_role_type, :app => @app_1)
    @int_role_2 = create(:role, :name => "int_role_b", :with_permissions => [perm_1, perm_2], :role_type => int_role_type, :app => @app_1)
    @ext_role_1 = create(:role, :name => "ext_role_a", :with_permissions => [perm_1, perm_2, perm_3], :role_type => ext_role_type, :app => @app_1)

    @root_user = create(:system_user, :admin, :with_casino_ids => [1000])
    @system_user_1 = create(:system_user, :roles => [@int_role_1], :with_casino_ids => [1000])
    @system_user_2 = create(:system_user, :roles => [@int_role_1], :with_casino_ids => [1003])
    @system_user_3 = create(:system_user, :roles => [@int_role_1], :with_casino_ids => [1003])
    @system_user_4 = create(:system_user, :roles => [@int_role_1], :with_casino_ids => [1003, 1007])
    @system_user_5 = create(:system_user, :roles => [@int_role_1], :with_casino_ids => [1000])
    @system_user_6 = create(:system_user, :roles => [@ext_role_1], :with_casino_ids => [1000])
    @system_user_7 = create(:system_user, :roles => [@int_role_2], :with_casino_ids => [1000])
  end

  describe "[16] User Change log" do
    def expect_target_casino_id(change_log, system_user)
      expect(change_log.target_casino_id).to eq system_user.active_casino_ids.first
    end

    it "[16.1] 1000 user successfully edit 1003 user" do
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit edit_roles_system_user_path(@system_user_2)

      within ("div#content form") do
        choose("#{@int_role_2.name.titleize}")
        click_button(I18n.t("general.confirm"))
      end

      cls = ChangeLog.all
      expect(cls.length).to eq 1
      expect(cls[0].action_by['username']).to eq "#{@system_user_1.username}@#{@system_user_1.domain.name}"
      expect(cls[0].action_by['casino_ids']).to eq @system_user_1.active_casino_ids
      expect(cls[0].created_at).to be_kind_of(Time)
      expect(cls[0].action).to eq "edit_role"
      expect(cls[0].target_username).to eq @system_user_2.username
      expect_target_casino_id(cls[0], @system_user_2)
      expect(cls[0].change_detail['app_name']).to eq @app_1.name
      expect(cls[0].change_detail['from']).to eq @int_role_1.name
      expect(cls[0].change_detail['to']).to eq @int_role_2.name
    end

    it "[16.2] 1003 user successfully edit 1003 user" do
      login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
      visit edit_roles_system_user_path(@system_user_3)

      within ("div#content form") do
        choose("#{@int_role_2.name.titleize}")
        click_button(I18n.t("general.confirm"))
      end

      cls = ChangeLog.all
      expect(cls.length).to eq 1
      expect(cls[0].action_by['username']).to eq "#{@system_user_2.username}@#{@system_user_2.domain.name}"
      expect(cls[0].action_by['casino_ids']).to eq @system_user_2.active_casino_ids
      expect(cls[0].created_at).to be_kind_of(Time)
      expect(cls[0].action).to eq "edit_role"
      expect(cls[0].target_username).to eq @system_user_3.username
      expect_target_casino_id(cls[0], @system_user_3)
      expect(cls[0].change_detail['app_name']).to eq @app_1.name
      expect(cls[0].change_detail['from']).to eq @int_role_1.name
      expect(cls[0].change_detail['to']).to eq @int_role_2.name
    end

    it "[16.3] 1000 user successfully edit 1003, 1007 user" do
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit edit_roles_system_user_path(@system_user_4)

      within ("div#content form") do
        choose("#{@int_role_2.name.titleize}")
        click_button(I18n.t("general.confirm"))
      end

      cls = ChangeLog.all
      expect(cls.length).to eq 2
      expect(cls[0].action_by['username']).to eq "#{@system_user_1.username}@#{@system_user_1.domain.name}"
      expect(cls[0].action_by['casino_ids']).to eq @system_user_1.active_casino_ids
      expect(cls[0].created_at).to be_kind_of(Time)
      expect(cls[0].action).to eq "edit_role"
      expect(cls[0].target_username).to eq @system_user_4.username
      expect(cls[0].target_casino_id).to eq 1003
      expect(cls[0].change_detail['app_name']).to eq @app_1.name
      expect(cls[0].change_detail['from']).to eq @int_role_1.name
      expect(cls[0].change_detail['to']).to eq @int_role_2.name

      expect(cls[1].action_by['username']).to eq "#{@system_user_1.username}@#{@system_user_1.domain.name}"
      expect(cls[1].action_by['casino_ids']).to eq @system_user_1.active_casino_ids
      expect(cls[1].created_at).to be_kind_of(Time)
      expect(cls[1].action).to eq "edit_role"
      expect(cls[1].target_username).to eq @system_user_4.username
      expect(cls[1].target_casino_id).to eq 1007
      expect(cls[1].change_detail['app_name']).to eq @app_1.name
      expect(cls[1].change_detail['from']).to eq @int_role_1.name
      expect(cls[1].change_detail['to']).to eq @int_role_2.name
    end

    it "[16.4] 1000 user successfully edit 1000 user" do
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit edit_roles_system_user_path(@system_user_5)

      within ("div#content form") do
        choose("#{@int_role_2.name.titleize}")
        click_button(I18n.t("general.confirm"))
      end

      cls = ChangeLog.all
      expect(cls.length).to eq 1
      expect(cls[0].action_by['username']).to eq "#{@system_user_1.username}@#{@system_user_1.domain.name}"
      expect(cls[0].action_by['casino_ids']).to eq @system_user_1.active_casino_ids
      expect(cls[0].created_at).to be_kind_of(Time)
      expect(cls[0].action).to eq "edit_role"
      expect(cls[0].target_username).to eq @system_user_5.username
      expect(cls[0].target_casino_id).to eq 1000
      expect(cls[0].change_detail['app_name']).to eq @app_1.name
      expect(cls[0].change_detail['from']).to eq @int_role_1.name
      expect(cls[0].change_detail['to']).to eq @int_role_2.name
    end

    it "[16.5] 1003, 1007 user successfully edit 1003 user" do
      mock_ad_account_profile(true, [1003, 1007])
      login("#{@system_user_4.username}@#{@system_user_4.domain.name}")
      visit edit_roles_system_user_path(@system_user_3)

      within ("div#content form") do
        choose("#{@int_role_2.name.titleize}")
        click_button(I18n.t("general.confirm"))
      end

      cls = ChangeLog.all
      expect(cls.length).to eq 1
      expect(cls[0].action_by['username']).to eq "#{@system_user_4.username}@#{@system_user_4.domain.name}"
      expect(cls[0].action_by['casino_ids']).to eq @system_user_4.active_casino_ids
      expect(cls[0].created_at).to be_kind_of(Time)
      expect(cls[0].action).to eq "edit_role"
      expect(cls[0].target_username).to eq @system_user_3.username
      expect_target_casino_id(cls[0], @system_user_3)
      expect(cls[0].change_detail['app_name']).to eq @app_1.name
      expect(cls[0].change_detail['from']).to eq @int_role_1.name
      expect(cls[0].change_detail['to']).to eq @int_role_2.name
    end

    def create_system_user_change_logs(created_ats = nil)
      content = { :action_by => {:username => 'user1', :casino_ids => [1000, 1003, 1007, 1014, 20000]}, :action => "edit_role", :change_detail => {:app_name => "user_management", :from => @int_role_1.name, :to => @int_role_2.name}, :type => 'SystemUserChangeLog' }
      resources = [
        [@system_user_1, 1000],
        [@system_user_2, 1000],
        [@system_user_3, 1000],
        [@system_user_4, 1003],
        [@system_user_4, 1007],
      ]
      resources.each_with_index do |resource, index|
        change_log = create(:change_log, content.merge(:target_username => resource[0].username))
        if created_ats
          change_log.created_at = created_ats[index]
          change_log.save
        end
        change_log.target_casinos.create(:target_casino_id => resource[1])
      end
    end

    it "[16.6] 1000 user show all change log" do
      create_system_user_change_logs

      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit index_edit_role_change_logs_path(:commit => true)

      rc_rows = all("div#content table tbody tr")
      expect(rc_rows.length).to eq 5
    end

    it "[16.7] 1003, 1007 user show target user casino 1003 and 1007 change log" do
      create_system_user_change_logs
      mock_ad_account_profile(true, [1003, 1007])

      login("#{@system_user_4.username}@#{@system_user_4.domain.name}")
      visit index_edit_role_change_logs_path(:commit => true)

      rc_rows = all("div#content table tbody tr")
      expect(rc_rows.length).to eq 2
    end

    it "[16.8] user change log authorized" do
      create_system_user_change_logs

      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit index_edit_role_change_logs_path(:commit => true)

      rc_rows = all("div#content table tbody tr")
      expect(rc_rows.length).to eq 5
    end

    it "[16.9] user change log unauthorized" do
      create_system_user_change_logs

      login("#{@system_user_7.username}@#{@system_user_7.domain.name}")
      visit index_edit_role_change_logs_path(:commit => true)

      rc_rows = all("div#content table tbody tr")
      expect(rc_rows.length).to eq 0
    end

    it "[16.10] Search change log by time range" do
      mock_time_at_now "2016-01-01 12:00:00"
      one_day_age = 1.day.ago
      create_system_user_change_logs([
        one_day_age,
        one_day_age,
        one_day_age,
        one_day_age,
        Time.now
      ])

      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit index_edit_role_change_logs_path(:commit => true, :start_time => "2016-01-01", :end_start => "2016-01-01")

      rc_rows = all("div#content table tbody tr")
      expect(rc_rows.length).to eq 1
    end

    it "[16.11] search change log by target user" do
      create_system_user_change_logs

      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit index_edit_role_change_logs_path(:commit => true, :target_system_user_name => @system_user_4.username)

      rc_rows = all("div#content table tbody tr")
      expect(rc_rows.length).to eq 2
    end
  end

  describe "[17] Support internal and external role" do
    it "[17.1] Show internal and external roles" do
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit edit_roles_system_user_path(@system_user_2)
      main_panel = find("div#content")
      expect(main_panel).to have_content @int_role_1.name.titleize
      expect(main_panel).to have_content @ext_role_1.name.titleize
    end

    it "[17.2] Show external roles" do
      login("#{@system_user_6.username}@#{@system_user_6.domain.name}")
      visit edit_roles_system_user_path(@system_user_2)
      main_panel = find("div#content")
      expect(main_panel).not_to have_content @int_role_1.name.titleize
      expect(main_panel).to have_content @ext_role_1.name.titleize
    end
  end
end
