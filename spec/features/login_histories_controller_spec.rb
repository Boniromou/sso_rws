require "feature_spec_helper"

describe LoginHistoriesController do
	def permission_with_login_history
    create(:permission, target: "login_history", name: "list", action: "list", app_id: @app.id)
  end

  def permission_with_system_user
    create(:permission, target: "system_user", name: "show", action: "show", app_id: @app.id)
  end

  def role_with_login_history
    create(:role, name: 'role_with_login_history', app_id: @app.id, with_permissions: [permission_with_system_user, permission_with_login_history])
  end

  def role_without_login_history
  	create(:role, name: 'role_without_login_history', app_id: @app.id, with_permissions: [permission_with_system_user])
  end

  def check_list(system_users=[], apps=[])
  	within("div#login_histories_result"){
	  	expect(page.all('table tbody tr').count).to eq system_users.size
	  	system_users.each_with_index do |system_user, index|
		  	within("table tbody tr:nth-child(#{index + 1})") {
			  	expect(page).to have_content("#{system_user.username}@#{system_user.domain.name}")
			  	expect(page).to have_content(apps[index].name.titleize)
			  }
			end
		}
  end

  before(:each) do
    create(:auth_source, :token => '192.1.1.1', :type => 'Ldap')
    mock_ad_account_profile
    @app = create(:app, :name => "user_management")
    @app1 = create(:app, :name => "cage")
    @root_user = create(:system_user, :admin, :with_casino_ids => [1000])
    @system_user_1 = create(:system_user, with_roles: [role_with_login_history], with_casino_ids: [1000])
    @system_user_2 = create(:system_user, with_roles: [role_with_login_history], with_casino_ids: [1003])
    @system_user_3 = create(:system_user, with_roles: [role_without_login_history], with_casino_ids: [1003, 1007])

    @his1 = create(:login_history)
    @his2 = create(:login_history, user_casino_ids: [1003, 1007], app_name: "gaming_operation")
    @his3 = create(:login_history, user_casino_ids: [1003, 1007, 1014])
  end

  describe "[29] Check login history permission", :js => true do
  	it "[29.1] verify the list login history" do
      login("#{@root_user.username}@#{@root_user.domain.name}")
  		visit login_histories_path
  		expect(find("input[name='start_time']").value).to eq (Time.now - (SEARCH_RANGE_FOR_LOGIN_HISTORY-1).days).strftime("%Y-%m-%d")
  		expect(find("input[name='end_time']").value).to eq Time.now.strftime("%Y-%m-%d")
  		expect(find('#username').text).to eq ''
  		apps = ['All'] + App.pluck(:name).map {|app| app.titleize}
  		expect(page).to have_select("app_id", :with_options => apps)
  		
  		click_button I18n.t("general.search")
  		titles = [I18n.t("change_log.user"), I18n.t("change_log.system"), I18n.t("login_history.login_time")]
      page.all('table thead tr th').each_with_index do |th, index|
        expect(th.text).to eq titles[index]
      end
   	end

  	it "[29.2] verify the list login history with non-1000 user" do
  		mock_ad_account_profile(true, [1003, 1007])
  		login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
  		visit login_histories_path
  		click_button I18n.t("general.search")
  		wait_for_ajax
  		check_list([@system_user_2, @his2.system_user], [@app, @his2.app])
  	end

  	it "[29.3] filter suspended casino group user login history" do
  		mock_ad_account_profile(true, [1003])
      login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
      @system_user_2.update_casinos([1007])
      visit login_histories_path
  		click_button I18n.t("general.search")
  		wait_for_ajax
  		check_list
  	end

  	it "[29.4] Only allow to view subset casino of user login history" do
  		mock_ad_account_profile(true, [1003])
  		login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
  		visit login_histories_path
  		click_button I18n.t("general.search")
  		wait_for_ajax
			check_list([@system_user_2], [@app])
  	end

  	it "[29.5] reject no-permission user" do
  		login("#{@system_user_3.username}@#{@system_user_3.domain.name}")
  		visit user_management_root_path
      expect(has_link?(I18n.t("login_history.list"))).to be false
      visit login_histories_path
      expect(page).to have_content(I18n.t("flash_message.not_authorize"))
  	end
  end

  describe "[30] Search login history by user", :js => true do
  	it "[30.1] search login history by user success" do
  		login("#{@root_user.username}@#{@root_user.domain.name}")
  		visit login_histories_path
  		fill_in "username", :with => "#{@his2.system_user.username}@#{@his2.domain.name}"
  		click_button I18n.t("general.search")
  		wait_for_ajax
			check_list([@his2.system_user], [@his2.app])
  	end

  	it "[30.2] search login history by user fail" do
  		login("#{@root_user.username}@#{@root_user.domain.name}")
  		visit login_histories_path
  		fill_in "username", :with => "#{@his2.system_user.username}@#{@his2.domain.name}aaa"
  		click_button I18n.t("general.search")
  		wait_for_ajax
  		check_list
  		expect(page).to have_content(I18n.t("login_history.search_system_user_error"))
  	end
  end

  describe "[31] Search login history by login time", :js => true do
  	before(:each) do
	    @his4 = create(:login_history, :sign_in_at => Time.now - (SEARCH_RANGE_FOR_LOGIN_HISTORY + 1).days)
	    @his5 = create(:login_history, :sign_in_at => Time.now)
	    @his6 = create(:login_history, :sign_in_at => Time.now - 2.days)
	    @his7 = create(:login_history, :sign_in_at => Time.now - 1.days)
	  end

  	it "[31.1] Search login time success with both time boxed filled (within time range)" do
  		login("#{@root_user.username}@#{@root_user.domain.name}")
  		visit login_histories_path
  		fill_in "start_time", :with => Date.today - SEARCH_RANGE_FOR_LOGIN_HISTORY.days
  		fill_in "end_time", :with => Date.yesterday
  		click_button I18n.t("general.search")
  		wait_for_ajax
  		check_list([@his7.system_user, @his6.system_user], [@his7.app, @his6.app])
  	end

  	it "[31.2] Search login time fail with both time boxed filled (without time range)" do
  		login("#{@root_user.username}@#{@root_user.domain.name}")
  		visit login_histories_path
  		fill_in "start_time", :with => Date.today - SEARCH_RANGE_FOR_LOGIN_HISTORY.days
  		fill_in "end_time", :with => Date.today
  		click_button I18n.t("general.search")
  		wait_for_ajax
  		check_list
  		expect(page).to have_content(I18n.t("login_history.search_range_error", :config_value => SEARCH_RANGE_FOR_LOGIN_HISTORY))
  	end

  	it "[31.3] search login time success with one time box empty" do
  		login("#{@root_user.username}@#{@root_user.domain.name}")
  		visit login_histories_path
  		fill_in "start_time", :with => ''
  		fill_in "end_time", :with => Date.yesterday
  		click_button I18n.t("general.search")
  		wait_for_ajax
  		check_list([@his7.system_user, @his6.system_user], [@his7.app, @his6.app])
  		expect(page).to have_content(I18n.t("login_history.search_range_remark", :config_value => SEARCH_RANGE_FOR_LOGIN_HISTORY))
  		expect(find("input[name='start_time']").value).to eq (Date.today - SEARCH_RANGE_FOR_LOGIN_HISTORY.days).to_s
  	end

  	it "[31.4] search login time fail with both time boxes empty" do
  		login("#{@root_user.username}@#{@root_user.domain.name}")
  		visit login_histories_path
  		fill_in "start_time", :with => ''
  		fill_in "end_time", :with => ''
  		click_button I18n.t("general.search")
  		wait_for_ajax
  		check_list
  		expect(page).to have_content(I18n.t("login_history.search_range_error", :config_value => SEARCH_RANGE_FOR_LOGIN_HISTORY))
  	end
  end

  describe "[32] Search by system", :js => true do
  	it "[32.1] Search login history by system success" do
  		login("#{@root_user.username}@#{@root_user.domain.name}")
  		visit login_histories_path
  		select "gaming_operation".titleize, :from => "app_id"
  		click_button I18n.t("general.search")
  		wait_for_ajax
  		check_list([@his2.system_user], [@his2.app])
  	end

  	it "[32.2] search login history by system fail (no record found)" do
  		login("#{@root_user.username}@#{@root_user.domain.name}")
  		visit login_histories_path
  		select "Cage", :from => "app_id"
  		click_button I18n.t("general.search")
  		wait_for_ajax
  		check_list
  		expect(page).to have_content(I18n.t("general.no_result_found"))
  	end
  end
end
