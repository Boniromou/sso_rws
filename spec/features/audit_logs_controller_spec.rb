require "feature_spec_helper"

describe AuditLogsController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = SystemUser.find_by_admin(1) || SystemUser.create(:id => 1, :username => "portal.admin", :status => true, :admin => true, :auth_source_id => 1)
  end

  after(:all) do
    Warden.test_reset!
  end
  
  describe '[9] Search audit log by Time' do
    before(:each) do
      AuditLog.delete_all
      @al1 = AuditLog.new({ :audit_target => "maintenance", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :action_at => "2014-09-29 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al1.save(:validate => false)
      @al2 = AuditLog.new({ :audit_target => "maintenance", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :action_at => "2014-09-30 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al2.save(:validate => false)
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
  end
  
  describe '[10] Search audit log by actioner' do
    before(:each) do
      AuditLog.delete_all
      @al1 = AuditLog.new({ :audit_target => "maintenance", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :action_at => "2014-09-29 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al1.save(:validate => false)
      @al2 = AuditLog.new({ :audit_target => "maintenance", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "ray.chan", :action_at => "2014-09-29 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al2.save(:validate => false)
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[10.1] search audit log by actioner' do
      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      fill_in "action_by", :with => "portal.admin"
      click_button I18n.t("general.search")
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).not_to have_selector("tr#audit#{@al2.id}_body")
    end
    
    it '[10.2] search empty in actioner' do
      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      click_button I18n.t("general.search")
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).to have_selector("tr#audit#{@al2.id}_body")
    end
  end
  
  describe '[11] Search audit log by action' do
    before(:each) do
      AuditLog.delete_all
      @al1 = AuditLog.new({ :audit_target => "maintenance", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :action_at => "2014-09-29 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al1.save(:validate => false)
      @al2 = AuditLog.new({ :audit_target => "maintenance", :action_type => "create", :action_error => "", :action => "reschedule", :action_status => "success", :action_by => "portal.admin", :action_at => "2014-09-29 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al2.save(:validate => false)
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
      select "All", :from => "target_name"
      select "All", :from => "action_list"
      click_button I18n.t("general.search")
      @al1.reload
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).to have_selector("tr#audit#{@al2.id}_body")
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
  describe '[24] Search audit log by target' do
    before(:each) do
      AuditLog.delete_all
      @al1 = AuditLog.new({ :audit_target => "maintenance", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :action_at => "2014-09-29 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al1.save(:validate => false)
      @al2 = AuditLog.new({ :audit_target => "system_user", :action_type => "update", :action_error => "", :action => "lock", :action_status => "success", :action_by => "portal.admin", :action_at => "2014-09-29 12:00:01", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al2.save(:validate => false)
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[24.1] search audit log by target' do
      login_as(@root_user, :scope => :system_user)
      visit search_audit_logs_path
      select "System", :from => "target_name"
      click_button I18n.t("general.search")
      @al1.reload
      expect(page.source).to have_selector("tr#audit#{@al2.id}_body")
    end
  end
end
