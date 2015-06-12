require "feature_spec_helper"

describe AuditLogsController do
  fixtures :auth_sources

  before(:all) do
    @root_user = create(:system_user, :admin)
  end
  
  describe '[9] Search audit log by Time' do
    before(:each) do
      AuditLog.delete_all
      @al1 = create(:audit_log, :success, :audit_target => "maintenance", :action_type => "create", :action => "create", :action_at => "2014-09-29 12:00:00")
      @al2 = create(:audit_log, :success, :audit_target => "maintenance", :action_type => "create", :action => "create", :action_at => "2014-09-30 12:00:00")
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[9.1] Search audit log by time' do
      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      fill_in "from", :with => "2014-9-29"
      fill_in "to", :with => "2014-9-29"
      click_button I18n.t("general.search")
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).not_to have_selector("tr#audit#{@al2.id}_body")
    end

    it '[9.2] search audit log exceed the time range' do
      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      start_str = "2014-9-29"
      end_time = Time.parse(start_str) + (SEARCH_RANGE_FOR_AUDIT_LOG + 1 ) * 86400
      end_str = "#{end_time.year}-#{end_time.month}-#{end_time.day}"
      fill_in "from", :with => start_str
      fill_in "from", :with => end_str
      click_button I18n.t("general.search")
      expect(page.source).to have_content(I18n.t("audit_log.search_range_error", :config_value => SEARCH_RANGE_FOR_AUDIT_LOG))
    end

    it '[9.3] search audit log without time range' do
      al = AuditLog.new({ :audit_target => "maintenance", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :action_at => @al1.action_at + (SEARCH_RANGE_FOR_AUDIT_LOG + 2 ) * 86400, :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      al.save(:validate => false)

      time_now = @al1.action_at + 1 * 86400
      allow(Time).to receive(:now).and_return(time_now)

      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      click_button I18n.t("general.search")
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).to_not have_selector("tr#audit#{al.id}_body")
    end
  end
  
  describe '[10] Search audit log by actioner' do
    before(:each) do
      AuditLog.delete_all
      @al1 = create(:audit_log, :success, :audit_target => "maintenance", :action_type => "create", :action => "create", :action_at => "2014-09-29 12:00:00")
      @al2 = create(:audit_log, :success, :audit_target => "maintenance", :action_type => "create", :action => "create", :action_by => "ray", :action_at => "2014-09-29 12:00:00")
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[10.1] search audit log by actioner' do
      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      fill_in "from", :with => "2014-9-29"
      fill_in "to", :with => "2014-9-29"
      fill_in "action_by", :with => "portal.admin"
      click_button I18n.t("general.search")
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).not_to have_selector("tr#audit#{@al2.id}_body")
    end
    
    it '[10.2] search empty in actioner' do
      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      fill_in "from", :with => "2014-9-29"
      fill_in "to", :with => "2014-9-29"
      click_button I18n.t("general.search")
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).to have_selector("tr#audit#{@al2.id}_body")
    end
  end
  
  describe '[11] Search audit log by action' do
    before(:each) do
      AuditLog.delete_all
      @al1 = create(:audit_log, :success, :audit_target => "maintenance", :action_type => "create", :action => "create", :action_at => "2014-09-29 12:00:00")
      @al2 = create(:audit_log, :success, :audit_target => "maintenance", :action_type => "update", :action => "reschedule", :action_at => "2014-09-29 12:00:00")
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
=begin
    it '[11.1] search audit log by action' do
      login_as(@root_user, :scope => :system_user)
      visit '/search_audit_logs'
      select "Maintenance", :from => "target_name"
      #TODO: need a javascript driver to get this work
      select "Create", :from => "action_list"
      fill_in "action_list", :with => "create"
      click_button I18n.t("general.search")
      @al1.reload
      page.source.should have_selector("tr#audit#{@al1.id}_body")
    end
=end
    it '[11.2] search all action' do
      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      fill_in "from", :with => "2014-9-29"
      fill_in "to", :with => "2014-9-30"
      select "All", :from => "target_name"
      select "All", :from => "action_list"
      click_button I18n.t("general.search")
      @al1.reload
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).to have_selector("tr#audit#{@al2.id}_body")
    end
  end

  describe '[13] Switch main functional tab' do
    it '[13.2] Click Audit log' do
      login_as(@root_user)
      visit '/home'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.audit_log")).click
      click_link I18n.t("auditlog.search_audit")
      expect(current_path).to eq(search_audit_logs_path)
    end
  end
=begin  
  describe '[23] Search audit log by action type' do
    before(:each) do
      AuditLog.delete_all
      @al1 = AuditLog.new({ :audit_target => "maintenance", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :action_at => "2014-09-29 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al1.save(:validate => false)
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[23.1] search audit log by action type' do
    
    end
  end
=end
  describe '[12] Search audit log by target' do
    before(:each) do
      AuditLog.delete_all
      @al1 = create(:audit_log, :success, :audit_target => "maintenance", :action_type => "create", :action => "create", :action_at => "2014-09-29 12:00:00")
      @al2 = create(:audit_log, :success, :audit_target => "system_user", :action_type => "update", :action => "lock", :action_at => "2014-09-29 12:00:00")
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[12.1] search audit log by target' do
      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      fill_in "from", :with => "2014-9-29"
      fill_in "to", :with => "2014-9-30"
      select "System", :from => "target_name"
      click_button I18n.t("general.search")
      @al1.reload
      expect(page.source).to have_selector("tr#audit#{@al2.id}_body")
    end
  end
end
