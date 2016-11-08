require "feature_spec_helper"

describe DomainLicenseesController do
	def app_id
		app = App.find_by_name('user_management')
    return app.id if app
    app = create(:app, name: 'user_management')
    return app.id
	end

	def login_root
		@root_user = create(:system_user, :admin, :with_casino_ids => [1000, 1003, 1007])
		login("#{@root_user.username}@#{@root_user.domain.name}")
	end

	def create_permission(target, action)
		info = {target: target, name: action, action: action, app_id: app_id}
    permission = Permission.where(info).first
    return permission if permission
    create(:permission, info)
  end

  def login_user_without_permissions
  	role_without_permission = create(:role, name: 'role_without_permission', app_id: app_id)
    casinos_ids = [1000, 1003, 1007]
    @current_user = create(:system_user, with_roles: [role_without_permission], with_casino_ids: casinos_ids)
    login("#{@current_user.username}@#{@current_user.domain.name}")
  end

  def login_user_with_permissions(permissions, casino_ids=[1000, 1003, 1007])
  	role_with_permission = create(:role, name: 'role_with_permission', app_id: app_id, with_permissions: permissions)
    @current_user = create(:system_user, with_roles: [role_with_permission], with_casino_ids: casino_ids)
    mock_ad_account_profile(true, casino_ids)
    login("#{@current_user.username}@#{@current_user.domain.name}")
  end

  def visit_domain_licensee
  	login_root
    visit domain_licensees_path
  end

  def general_create_domain_licensee(domain_name, licensee_name)
		select(domain_name, from: 'domain_id')
    select(licensee_name, from: 'licensee_id')
    find("button#create_domain_licensee").click
	end

  before(:each) do
		@permission_list = create_permission('domain_licensee_mapping', 'list')
		@permission_create = create_permission('domain_licensee_mapping', 'create')
		@permission_delete = create_permission('domain_licensee_mapping', 'delete')
	end

	describe "[20] List Domain Licensee mapping" do
		before(:each) do
			create(:domain, with_licensee: true)
		end

    it "[20.1] No permission for list domain licensee mapping" do
      login_user_without_permissions
      visit home_root_path
      click_link_or_button("Home")
      expect(has_css?("#domain_management_link")).to eq false
    end

    it "[20.2] List domain licensee mapping without create and delete permission" do
      login_user_with_permissions([@permission_list])
      visit domain_licensees_path

      titles = [I18n.t("domain.name"), I18n.t("domain_licensee.licensee"), I18n.t("casino.title"), I18n.t("general.updated_at"), I18n.t("general.operation")]
      page.all('table#domain_licensees thead tr th').each_with_index do |th, index|
        expect(th.text).to eq titles[index]
      end
      expect(has_css?("select#domain_id")).to eq false
      expect(has_css?("select#licensee_id")).to eq false
      expect(has_css?("button#create_domain_licensee")).to eq false
      expect(has_css?("#delete")).to eq false
    end

    it "[20.3] list domain licensee mapping with create permission" do
      login_user_with_permissions([@permission_list, @permission_create, @permission_delete])
      visit domain_licensees_path

      expect(has_css?("select#domain_id")).to eq true
      expect(has_css?("select#licensee_id")).to eq true
      expect(has_css?("button#create_domain_licensee")).to eq true
      expect(has_css?("#delete")).to eq true
    end
  end

  describe "[21] Create Domain licensee mapping", :js => true do
  	def get_casinos(licensee)
  		licensee.casinos.map{|casino| "[#{casino.name}, #{casino.id}]"}.join(", ")
  	end

  	def check_domain_licensee(domain, licensee)
  		within("table#domain_licensees tbody tr:nth-child(1)") {
		  	expect(page).to have_content(domain.name)
		  	expect(page).to have_content("#{licensee.name}[#{licensee.id}]")
		  	expect(page).to have_content(get_casinos(licensee))
		  }
  	end

    before :each do
      @domain1 = create(:domain)
      @domain2 = create(:domain, with_licensee: true)
      @domain3 = create(:domain)
      @licensee1 = create(:licensee, with_casino_ids: [1003, 1007])
      @licensee2 = create(:licensee)
    end

    after :each do
    	wait_for_ajax
    end

    it "[21.1] Create domain licensee mapping success" do
    	login_root
      visit domain_management_root_path
	    click_link I18n.t("domain_licensee.list")
	    wait_for_ajax
  		expect(page).to have_select("domain_id", :with_options => [@domain1.name])
  		expect(page).to have_select("licensee_id", :with_options => ["#{@licensee1.name}[#{@licensee1.id}]"])
  		expect(find("#licensee_casinos").text).to eq get_casinos(@licensee1)
      general_create_domain_licensee(@domain1.name, "#{@licensee1.name}[#{@licensee1.id}]")
      wait_for_ajax
      check_flash_message(I18n.t('domain_licensee.create_mapping_successfully'))
      check_domain_licensee(@domain1, @licensee1)
    end

    it "[21.2] Create domain licensee mapping fail - domain bounded with the licensee" do
    	visit_domain_licensee
    	@domain1.update_attributes(licensee_id: @licensee2.id)
    	general_create_domain_licensee(@domain1.name, "#{@licensee1.name}[#{@licensee1.id}]")
    	wait_for_ajax
      check_flash_message(I18n.t('domain_licensee.create_mapping_fail_domain_used'))
    end

    it "[21.5] Create domain licensee mapping fail - licensee bounded with another domain" do
      visit_domain_licensee
    	@domain3.update_attributes(licensee_id: @licensee1.id)
    	general_create_domain_licensee(@domain1.name, "#{@licensee1.name}[#{@licensee1.id}]")
    	wait_for_ajax
      check_flash_message(I18n.t('domain_licensee.create_mapping_fail_licensee_used'))
    end

    it "[21.3] Create domain licensee mapping success audit log" do
    	visit_domain_licensee
      general_create_domain_licensee(@domain1.name, "#{@licensee1.name}[#{@licensee1.id}]")
      wait_for_ajax
      filters = {
        audit_target: 'domain_licensee',
        action_type: 'create',
        action: 'create',
        action_status: 'success',
        action_by: @root_user.username
      }
      expect(AuditLog.where(filters)).not_to eq []
    end

    it "[21.4] Create domain licensee mapping fail audit log" do
      visit_domain_licensee
    	@domain1.update_attributes(licensee_id: @licensee1.id)
    	general_create_domain_licensee(@domain1.name, "#{@licensee1.name}[#{@licensee1.id}]")
    	wait_for_ajax
      filters = {
        audit_target: 'domain_licensee',
        action_type: 'create',
        action: 'create',
        action_status: 'fail',
        action_by: @root_user.username
      }
      expect(AuditLog.where(filters)).not_to eq []
    end
  end

  describe "[22] Delete Domain Licensee Mapping" do
    before :each do
      @domain1 = create(:domain, with_licensee: true)
    end

    it "[22.1] Delete Domain Licensee Mapping success" do
    	visit_domain_licensee
      find("#delete_#{@domain1.id}").click
      check_flash_message(I18n.t('domain_licensee.delete_mapping_successfully'))
    end

    it "[22.2] delete Domain Licensee Mapping fail with record updated" do
      visit_domain_licensee
    	@domain1.update_attributes(licensee_id: nil)
      find("#delete_#{@domain1.id}").click
      check_flash_message(I18n.t('domain_licensee.delete_mapping_fail'))
    end

    it "[22.3] delete Domain Licensee Mapping success audit log" do
      visit_domain_licensee
      find("#delete_#{@domain1.id}").click
      filters = {
        audit_target: 'domain_licensee',
        action_type: 'delete',
        action: 'delete',
        action_status: 'success',
        action_by: @root_user.username
      }
      expect(AuditLog.where(filters)).not_to eq []
    end

    it "[22.4] delete Domain Licensee Mapping fail audit log" do
      visit_domain_licensee
    	@domain1.licensee_id = nil
    	@domain1.save!
      find("#delete_#{@domain1.id}").click
      filters = {
        audit_target: 'domain_licensee',
        action_type: 'delete',
        action: 'delete',
        action_status: 'fail',
        action_by: @root_user.username
      }
      expect(AuditLog.where(filters)).not_to eq []
    end
  end

  describe "[23] Domain Licensee Mapping change log" do
  	def visit_domain_licensee_log
  		login_root
  		visit create_domain_licensee_change_logs_path
  	end

  	def check_change_logs(domain, licensee, action)
  		licensee.casinos.each_with_index do |casino, index|
	      within("div#domain_licensee_change_logs table tbody tr:nth-child(#{index + 1})") {
			  	expect(page).to have_content(domain.name)
			  	expect(page).to have_content("#{licensee.name}[#{licensee.id}]")
			  	expect(page).to have_content("[#{casino.name}, #{casino.id}]")
			  	expect(page).to have_content(action)
			  	expect(page).to have_content(@root_user.username)
			  }
	    end
  	end

  	before :each do
      @domain1 = create(:domain)
      @domain2 = create(:domain, with_licensee: true)
      @licensee1 = create(:licensee, with_casino_ids: [1000, 1003, 1007])
      @permission_list_log = create_permission('domain_licensee_mapping', 'list_log')
    end

    it "[23.1] No Premission for List Domain Licensee mapping change log" do
      login_user_with_permissions([@permission_list])
      visit domain_licensees_path
      expect(has_text?(I18n.t("general.log"))).to eq false
    end

    it "[23.2] List Domain Licensee mapping change log" do
      visit_domain_licensee_log
      titles = [I18n.t('domain.name'), I18n.t('domain_licensee.licensee'), I18n.t('casino.title'), I18n.t('general.action'), I18n.t('general.action_at'), I18n.t('general.action_by')]
      page.all('div#domain_licensee_change_logs table thead tr th').each_with_index do |th, index|
        expect(th.text).to eq titles[index]
      end
    end

    it "[23.3] Create change log for create Domain Licensee mapping" do
      visit_domain_licensee
      general_create_domain_licensee(@domain1.name, "#{@licensee1.name}[#{@licensee1.id}]")
      visit create_domain_licensee_change_logs_path
      check_change_logs(@domain1, @licensee1, "Create")
    end

    it "[23.4] Create change log for delete Domain Licensee mapping" do
      visit_domain_licensee
      licensee2 = @domain2.licensee
      find("#delete_#{@domain2.id}").click
      visit create_domain_licensee_change_logs_path
      check_change_logs(@domain2, licensee2, "Delete")
    end

    it "[23.5] 1000 user show all change log" do
      visit_domain_licensee
      general_create_domain_licensee(@domain1.name, "#{@licensee1.name}[#{@licensee1.id}]")
      click_link I18n.t("general.logout")
      login_user_with_permissions([@permission_list_log])
      visit create_domain_licensee_change_logs_path
      expect(page.all('div#domain_licensee_change_logs table tbody tr').count).to eq 3
      check_change_logs(@domain1, @licensee1, "Create")
    end

    it "[23.6] 1003, 1007 user show target user casino 1003 and 1007 change log" do
      visit_domain_licensee
      general_create_domain_licensee(@domain1.name, "#{@licensee1.name}[#{@licensee1.id}]")
      click_link I18n.t("general.logout")
      login_user_with_permissions([@permission_list_log], [1003, 1007])
      visit create_domain_licensee_change_logs_path
      
      expect(page.all('div#domain_licensee_change_logs table tbody tr').count).to eq 2
      [1003, 1007].each_with_index do |casino_id, index|
      	casino = Casino.find(casino_id)
	      within("div#domain_licensee_change_logs table tbody tr:nth-child(#{index + 1})") {
			  	expect(page).to have_content(@domain1.name)
			  	expect(page).to have_content("#{@licensee1.name}[#{@licensee1.id}]")
			  	expect(page).to have_content("[#{casino.name}, #{casino.id}]")
			  	expect(page).to have_content("Create")
			  	expect(page).to have_content(@root_user.username)
			  }
	    end
    end
  end
end