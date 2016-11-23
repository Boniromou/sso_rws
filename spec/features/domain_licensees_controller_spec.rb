require "feature_spec_helper"

describe DomainLicenseesController do
  before(:each) do
    app = create(:app, name: APP_NAME)
    @app_id = app.id
  end

  def auth_source_id
    auth_source = AuthSource.first || create(:auth_source)
    auth_source.id
  end

	def login_root
		@root_user = create(:system_user, :admin, :with_casino_ids => [1000])
		login("#{@root_user.username}@#{@root_user.domain.name}")
	end

  def login_user(role, domain_name=nil, casino_ids=[1000])
    if domain_name
      system_user = create(:system_user, :roles => [role], :domain_name => domain_name, :with_casino_ids => casino_ids)
    else
      system_user = create(:system_user, :roles => [role], :with_casino_ids => casino_ids)
    end
    mock_ad_account_profile(true, casino_ids)
    login("#{system_user.username}@#{system_user.domain.name}")
  end

	def create_permission(target, action)
		info = {target: target, name: action, action: action, app_id: @app_id}
    permission = Permission.where(info).first
    return permission if permission
    create(:permission, info)
  end

  def role_without_permission
    create(:role, name: 'role_without_permission', app_id: @app_id)
  end

  def role_with_permission_domain
    permission_domain = create_permission('domain', 'list')
    create(:role, app_id: @app_id, with_permissions: [permission_domain])
  end

  def role_with_permission_list
    permission_list = create_permission('domain_licensee_mapping', 'list')
    create(:role, app_id: @app_id, with_permissions: [permission_list])
  end

  def role_with_permission
    permission_list = create_permission('domain_licensee_mapping', 'list')
    permission_create = create_permission('domain_licensee_mapping', 'create')
    permission_delete = create_permission('domain_licensee_mapping', 'delete')
    permission_list_log = create_permission('domain_licensee_mapping', 'list_log')
    create(:role, app_id: @app_id, with_permissions: [permission_list, permission_create, permission_delete, permission_list_log])
  end

  def visit_domain_licensee
  	login_root
    visit domain_licensees_path
  end
	describe "[20] List Domain Licensee mapping" do
    it "[20.1] No permission for list domain licensee and list domain mapping" do
      login_user(role_without_permission)
      visit home_root_path
      click_link_or_button("Home")
      expect(has_css?("#domain_management_link")).to eq false
    end

    it "[20.2] List domain licensee mapping without create and delete permission" do
      login_user(role_with_permission_list)
      visit domain_licensees_path
      titles = [I18n.t("domain.name"), I18n.t("domain_licensee.licensee"), I18n.t("casino.title"), I18n.t("general.updated_at"), I18n.t("general.operation")]
      page.all('table#domain_licensees thead tr th').each_with_index do |th, index|
        expect(th.text).to eq titles[index]
      end
      expect(page.all('table#domain_licensees tbody tr').count).to eq 1
      expect(has_css?("select#domain_id")).to eq false
      expect(has_css?("select#licensee_id")).to eq false
      expect(has_css?("button#create_domain_licensee")).to eq false
      expect(has_css?("#delete")).to eq false
    end

    it "[20.3] list domain licensee mapping with create permission" do
      login_user(role_with_permission)
      visit domain_licensees_path
      expect(page.all('table#domain_licensees tbody tr').count).to eq 1
      expect(has_css?("select#domain_id")).to eq true
      expect(has_css?("select#licensee_id")).to eq true
      expect(has_css?("button#create_domain_licensee")).to eq true
      expect(has_css?("#delete")).to eq true
    end
  end

  describe "[21] Create Domain licensee mapping", :js => true do
    def general_create_domain_licensee(domain_name, licensee_name)
      select(domain_name, from: 'domain_id')
      select(licensee_name, from: 'licensee_id')
      find("button#create_domain_licensee").click
    end

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

    it "[21.1] Create domain licensee mapping success" do
      create(:domain, :name => '1003.com')
      licensee = create(:licensee, :id => 1003, :with_casino_ids => [1003, 1007])
      licensee1 = create(:licensee, :id => 1007, :with_domain => '1007.com')
      domain = licensee1.domain
      login_root
      visit domain_management_root_path
      click_link I18n.t("domain_licensee.list")
      wait_for_ajax
  		expect(page).to have_select("domain_id", :with_options => ['1003.com', '1007.com'])
  		expect(page).to have_select("licensee_id", :with_options => ["#{licensee.name}[#{licensee.id}]"])
  		expect(find("#licensee_casinos").text).to eq get_casinos(licensee)
      general_create_domain_licensee('1007.com', "#{licensee.name}[#{licensee.id}]")
      wait_for_ajax
      check_flash_message(I18n.t('domain_licensee.create_mapping_successfully'))
      check_domain_licensee(domain, licensee)
    end

    it "[21.5] Create domain licensee mapping fail - licensee bounded with another domain" do
      create(:domain, :name => '1007.com')
      licensee = create(:licensee, :id => 1007)
      domain = create(:domain, :name => '1008.com')
      visit_domain_licensee
    	licensee.update_attributes(domain_id: domain.id)
    	general_create_domain_licensee('1007.com', "#{licensee.name}[#{licensee.id}]")
    	wait_for_ajax
      check_flash_message(I18n.t('domain_licensee.create_mapping_fail_licensee_used'))
    end

    it "[21.3] Create domain licensee mapping success audit log" do
      create(:domain, :name => '1003.com')
      licensee = create(:licensee, :id => 1003)
    	visit_domain_licensee
      general_create_domain_licensee('1003.com', "#{licensee.name}[#{licensee.id}]")
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
      domain = create(:domain, :name => '1007.com')
      licensee = create(:licensee, :id => 1007)
      visit_domain_licensee
    	licensee.update_attributes(domain_id: domain.id)
    	general_create_domain_licensee('1007.com', "#{licensee.name}[#{licensee.id}]")
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
      @licensee = create(:licensee, :id => 1003, :with_domain => '1003.com')
    end

    it "[22.1] Delete Domain Licensee Mapping success" do
    	visit_domain_licensee
      find("#delete_#{@licensee.id}").click
      check_flash_message(I18n.t('domain_licensee.delete_mapping_successfully'))
    end

    it "[22.2] delete Domain Licensee Mapping fail with record updated" do
      visit_domain_licensee
    	@licensee.update_attributes(domain_id: nil)
      find("#delete_#{@licensee.id}").click
      check_flash_message(I18n.t('domain_licensee.delete_mapping_fail'))
    end

    it "[22.3] delete Domain Licensee Mapping success audit log" do
      visit_domain_licensee
      find("#delete_#{@licensee.id}").click
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
    	@licensee.update_attributes(domain_id: nil)
      find("#delete_#{@licensee.id}").click
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
    def general_create_domain_licensee(domain_name, licensee_name)
      select(domain_name, from: 'domain_id')
      select(licensee_name, from: 'licensee_id')
      find("button#create_domain_licensee").click
    end

  	def visit_domain_licensee_log
  		login_root
  		visit create_domain_licensee_change_logs_path
  	end

  	def check_change_logs(domain, licensee, casino_ids, action)
  		casino_ids.each_with_index do |casino_id, index|
        casino = Casino.find(casino_id)
	      within("div#domain_licensee_change_logs table tbody tr:nth-child(#{index + 1})") {
			  	expect(page).to have_content(domain.name)
			  	expect(page).to have_content("#{licensee.name}[#{licensee.id}]")
			  	expect(page).to have_content("[#{casino.name}, #{casino.id}]")
			  	expect(page).to have_content(action)
			  	expect(page).to have_content(@root_user.username)
			  }
	    end
  	end

    it "[23.1] No Premission for List Domain Licensee mapping change log" do
      login_user(role_with_permission_list)
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
      licensee = create(:licensee, :id => 1003, :with_casino_ids => [1003, 1007])
      licensee1 = create(:licensee, :id => 1007, :with_domain => '1007.com')
      domain = licensee1.domain
      visit_domain_licensee
      click_link I18n.t("domain_licensee.list")
      general_create_domain_licensee('1007.com', "#{licensee.name}[#{licensee.id}]")
      visit create_domain_licensee_change_logs_path
      check_change_logs(domain, licensee, [1003, 1007], "Create")
    end

    it "[23.4] Create change log for delete Domain Licensee mapping" do
      licensee = create(:licensee, :id => 1003, :with_domain => '1003.com', :with_casino_ids => [20000])
      visit_domain_licensee
      find("#delete_#{licensee.id}").click
      visit create_domain_licensee_change_logs_path
      check_change_logs(licensee.domain, licensee, [20000], "Delete")
    end

    it "[23.5] 1000 user show all change log" do
      auth_source = create(:auth_source)
      licensee = create(:licensee, :id => 1003, :with_casino_ids => [1000, 1003, 1007])
      domain = create(:domain, :name => '1003.com', :auth_source_id => auth_source.id)
      visit_domain_licensee
      general_create_domain_licensee('1003.com', "#{licensee.name}[#{licensee.id}]")
      click_link I18n.t("general.logout")
      login_user(role_with_permission, '1003.com')
      visit create_domain_licensee_change_logs_path
      expect(page.all('div#domain_licensee_change_logs table tbody tr').count).to eq 3
      check_change_logs(domain, licensee, [1000, 1003, 1007], "Create")
    end

    it "[23.6] 1003, 1007 user show target user casino 1003 and 1007 change log" do
      auth_source = create(:auth_source)
      licensee = create(:licensee, :id => 1003, :with_casino_ids => [1003, 1007, 1014])
      domain = create(:domain, :name => '1003.com', :auth_source_id => auth_source.id)
      visit_domain_licensee
      general_create_domain_licensee('1003.com', "#{licensee.name}[#{licensee.id}]")
      click_link I18n.t("general.logout")

      login_user(role_with_permission, '1003.com', [1003, 1007])
      visit create_domain_licensee_change_logs_path
      expect(page.all('div#domain_licensee_change_logs table tbody tr').count).to eq 2
      check_change_logs(domain, licensee, [1003, 1007], "Create")
    end
  end
end