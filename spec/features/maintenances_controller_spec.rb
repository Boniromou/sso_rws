require "feature_spec_helper"

describe MaintenancesController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = SystemUser.find_by_admin(1)
  end

  after(:all) do
    Warden.test_reset!
  end
  
  describe '[12] Switch main functional tab' do
    it '[12.1] Click Administration' do
      login_as(@root_user, :scope => :system_user)
      visit '/dashboard'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.administration")).click
      click_link I18n.t("user.list_users")
      expect(current_path).to eq(system_users_path)
    end
    
    it '[12.2] Click Audit Log' do
      login_as(@root_user, :scope => :system_user)
      visit '/dashboard'
      first('ul.dropdown-menu').find('a', :text => I18n.t("header.audit_log")).click
      click_link I18n.t("auditlog.search_audit")
      expect(current_path).to eq(search_audit_logs_path)
    end
  end

  describe '[13] Create Maintenance' do
    before(:each) do
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)

      @m1 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => 1007, :start_time => '2014-09-18 10:00:00', :end_time => '2014-09-18 15:00:00', :duration => 18000, :allow_test_account => true, :status => 'scheduled'})
      @m1.save(:validate => false)
    end

    after(:each) do
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
    end

    it '[13.1] create a single property maintenance' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Create Maintenance')
      select('1003', :from => 'properties')
      fill_in 'start_time', :with => '2014-09-18 14:00:00' # input Beijing time
      click_button I18n.t("general.confirm")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      @p1.reload
      results = @p1.maintenances
      results[0].start_time
      expect(results.length).to eq(1)
      expect(results[0].maintenance_type_id).to eq(@mt1.id)
      expect(results[0].start_time).to eq('2014-09-18 06:00:00')
      expect(results[0].end_time).to eq('2014-09-18 06:30:00')
      expect(results[0].duration).to eq(1800)
      expect(results[0].allow_test_account).to eq(true)
      expect(results[0].status).to eq('scheduled')
    end

    it '[13.2] audit log for Create Maintenance' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Create Maintenance')
      select('1003', :from => 'properties')
      fill_in 'start_time', :with => '2014-09-18 22:00:00' # input Beijing time
      click_button I18n.t("general.confirm")
      al = AuditLog.first
      expect(al.audit_target).to eq("maintenance")
      expect(al.action_type).to eq("create")
      expect(al.action).to eq("create")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[13.3] Property Validation in Create maintenance' do
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Create Maintenance')
      fill_in 'start_time', :with => '2014-09-18 22:00:00' # input Beijing time
      click_button I18n.t("general.confirm")
      expect(page).to have_content I18n.t("alert.invalid_property")
      @p1.reload
      results = @p1.maintenances
      expect(results.length).to eq(0)
    end

    it '[13.4] Check duplicated maintenance' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Create Maintenance')
      select('1007', :from => 'properties')
      fill_in 'start_time', :with => '2014-09-18 20:00:00'  # input Beijing time
      click_button I18n.t("general.confirm")
      expect(page).to have_content I18n.t("alert.time_conflict", {:maintenance_id => @m1.reload.id})
      @p2.reload
      results = @p2.maintenances
      expect(results.length).to eq(1)
    end 

    it '[13.5] Time Validation in Create maintenance (not empty)' do
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Create Maintenance')
      select('1003', :from => 'properties')
      click_button I18n.t("general.confirm")
      expect(page).to have_content I18n.t("alert.invalid_time_range")
      @p1.reload
      results = @p1.maintenances
      expect(results.length).to eq(0)
    end

    it '[13.6] Time validation in Create maintenance (Start time > now)' do
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Create Maintenance')
      select('1003', :from => 'properties')
      fill_in 'start_time', :with => '2014-09-17 18:00:00'  # input Beijing time
      click_button I18n.t("general.confirm")
      expect(page).to have_content I18n.t("alert.invalid_time_range")
      @p1.reload
      results = @p1.maintenances
      expect(results.length).to eq(0)
    end

    it '[13.7] Check create never end Maintenance' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Create Maintenance')
      select('1003', :from => 'properties')
      fill_in 'start_time', :with => '2014-09-18 14:00:00'   # input Beijing time
      page.check 'never_end'
      click_button I18n.t("general.confirm")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      @p1.reload
      results = @p1.maintenances
      results[0].start_time
      expect(results.length).to eq(1)
      expect(results[0].maintenance_type_id).to eq(@mt1.id)
      expect(results[0].start_time).to eq('2014-09-18 06:00:00')
      expect(results[0].end_time.strftime("%Y-%m-%d %H:%M:%S")).to eq('2999-01-01 00:00:00')
      expect(results[0].duration).to eq(1800)
      expect(results[0].allow_test_account).to eq(true)
      expect(results[0].status).to eq('scheduled')
    end
  end

  describe '[15] Support Multi-Properties maint.' do
    before(:each) do
      Maintenance.delete_all
      Property.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)
    end

    after(:each) do
      Maintenance.delete_all
      Property.delete_all
    end

    it '[15.1] Support Multi-Properties maint.' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Create Maintenance')
      select('1003', :from => 'properties')
      select('1007', :from => 'properties')
      fill_in 'start_time', :with => '2014-09-18 14:00:00'
      click_button I18n.t("general.confirm")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      results = Maintenance.all
      expect(results.length).to eq(2)
      expect(results[0].property_id).to eq(@p1.id)
      expect(results[0].maintenance_type_id).to eq(@mt1.id)
      expect(results[0].start_time).to eq('2014-09-18 06:00:00')
      expect(results[0].end_time).to eq('2014-09-18 06:30:00')
      expect(results[0].duration).to eq(1800)
      expect(results[0].allow_test_account).to eq(true)
      expect(results[0].status).to eq('scheduled')
      expect(results[1].property_id).to eq(@p2.id)
      expect(results[1].maintenance_type_id).to eq(@mt1.id)
      expect(results[1].start_time).to eq('2014-09-18 06:00:00')
      expect(results[1].end_time).to eq('2014-09-18 06:30:00')
      expect(results[1].duration).to eq(1800)
      expect(results[1].allow_test_account).to eq(true)
      expect(results[1].status).to eq('scheduled')
    end
  end
  
  describe '[16] Search maint. by Property' do
    before(:each) do
      Maintenance.delete_all
      Property.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)
      @m1 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => 1003, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 18000, :allow_test_account => true, :status => 'scheduled'})
      @m1.save(:validate => false)      
    end
    
    after(:each) do
      Maintenance.delete_all
      Property.delete_all
    end
    
    it '[16.1] search all criteria' do
      @time_now = Time.parse("2014-09-18 13:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => I18n.t("general.search")).click
      page.find("input#search_button").click
      @m1.reload
      expect(page.source).to have_selector("tr#maint#{@m1.id}_body")
    end
  end

  describe '[17] Search maint. by date range' do
    before(:each) do
      Maintenance.delete_all
      Property.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)
      @m1 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => 1003, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 18000, :allow_test_account => true, :status => 'scheduled'})
      @m1.save(:validate => false)      
    end
    
     after(:each) do
      Maintenance.delete_all
      Property.delete_all
    end
    
    it '[17.1] search by date range' do
      @time_now = Time.parse("2014-09-18 13:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => I18n.t("general.search")).click
      fill_in "from", :with => "2014-9-18"
      fill_in "to", :with => "2014-9-18"
      click_button I18n.t("general.search")
      @m1.reload
      expect(page.source).to have_selector("tr#maint#{@m1.id}_body")
    end
  end
  
  describe '[18] Search maint. by Status' do
    before(:each) do
      Maintenance.delete_all
      Property.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)
      @m1 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => 1003, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 18000, :allow_test_account => true, :status => 'scheduled'})
      @m1.save(:validate => false)      
    end
    
     after(:each) do
      Maintenance.delete_all
      Property.delete_all
    end
    
    it '[18.1] search by status' do
      @time_now = Time.parse("2014-09-18 13:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => I18n.t("general.search")).click
      find(:css, "#selected_status_[value='scheduled']").set(true)
      find(:css, "#selected_status_[value='activated']").set(false)
      find(:css, "#selected_status_[value='completed']").set(true)
      find(:css, "#selected_status_[value='cancelled']").set(false)
      find(:css, "#selected_status_[value='expired']").set(false)
      click_button I18n.t("general.search")
      @m1.reload
      expect(page.source).to have_selector("tr#maint#{@m1.id}_body")
    end
  end
  
  describe '[19] reschedule maintenance' do
    before(:each) do
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)

      @m1 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p1.id, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 18000, :allow_test_account => true, :status => 'scheduled'})
      @m1.save(:validate => false)      

      @m2 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p2.id, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 18000, :allow_test_account => true, :status => 'scheduled'})
      @m2.save(:validate => false)

      @m3 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p2.id, :start_time => '2014-09-20 12:00:00', :end_time => '2014-09-20 15:00:00', :duration => 18000, :allow_test_account => true, :status => 'scheduled'})
      @m3.save(:validate => false)

      @m4 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p2.id, :start_time => '2014-09-21 12:00:00', :end_time => '2014-09-21 15:00:00', :duration => 18000, :allow_test_account => true, :status => 'scheduled'})
      @m4.save(:validate => false)
    end

    after(:each) do
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
    end

    it '[19.1] reschedule maintenance' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance') 
      click_link("reschedule_#{@m1.id}")
      fill_in 'start_time', :with => '2014-09-18 10:00:00'
      click_button I18n.t("general.confirm")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      @m1.reload
      expect(@m1.start_time).to eq('2014-09-18 02:00:00')
      expect(@m1.end_time).to eq('2014-09-18 07:00:00')
      expect(@m1.duration).to eq(18000)
      expect(@m1.lock_version).to eq(1)
    end
    
    it '[19.2] audit log for Reshedule Maintenance' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance') 
      click_link("reschedule_#{@m1.id}")
      fill_in 'start_time', :with => '2014-09-18 10:00:00'
      click_button I18n.t("general.confirm")
      @m1.reload
      al = AuditLog.first
      expect(al.audit_target).to eq("maintenance")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("reschedule")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[19.3] Lock version control for reschedule maintenance - scheduled tab' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      click_link("reschedule_#{@m2.id}")
      m2 = Maintenance.find_by_id(@m2.id)
      m2.update_attribute :start_time, '2014-09-18 10:00:00'
      click_button I18n.t("general.confirm")
      check_flash_message I18n.t("flash_message.lock_error")
      expect(page.current_path).to eq(scheduled_maintenance_path)
      @m2.reload
      expect(@m2.start_time.strftime("%Y-%m-%d %H:%M:%S")).to eq('2014-09-18 11:00:00')
      expect(@m2.end_time.strftime("%Y-%m-%d %H:%M:%S")).to eq('2014-09-18 15:00:00')
      expect(@m2.duration).to eq(18000)
      expect(@m2.lock_version).to eq(1)
    end

    it '[19.4] Time validation for reschedule maintenance - scheduled tab' do
      @time_now = Time.parse("2014-09-20 11:59:55")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      @time_now = Time.parse("2014-09-20 12:00:01")
      allow(Time).to receive(:now).and_return(@time_now)
      click_link("reschedule_#{@m3.id}")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      check_flash_message I18n.t("flash_message.time_invalid")
    end

    it '[19.5] Lock version control for reschedule maintenance - reschedule page' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      click_link("reschedule_#{@m2.id}")
      fill_in 'start_time', :with => '2014-09-18 13:00:00'
      m2 = Maintenance.find_by_id(@m2.id)
      m2.update_attribute :start_time, '2014-09-18 11:00:00'
      click_button I18n.t("general.confirm")
      check_flash_message I18n.t("flash_message.lock_error")
      expect(page.current_path).to eq(scheduled_maintenance_path)
      @m2.reload
      expect(@m2.start_time.strftime("%Y-%m-%d %H:%M:%S")).to eq('2014-09-18 11:00:00')
      expect(@m2.end_time.strftime("%Y-%m-%d %H:%M:%S")).to eq('2014-09-18 15:00:00')
      expect(@m2.duration).to eq(18000)
      expect(@m2.lock_version).to eq(1)
    end

    it '[19.6] Time validation for reschedule maintenance - reschedule page' do
      @time_now = Time.parse("2014-09-21 11:55:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      click_link("reschedule_#{@m4.id}")
      expect(page).to have_content(I18n.t("maintenance.maintenance_time"))
      fill_in 'start_time', :with => '2014-09-21 16:00:00'
      @time_now = Time.parse("2014-09-21 12:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      click_button I18n.t("general.confirm")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      m4 = Maintenance.find_by_id(@m4.id)
      expect(m4.start_time).to eq(@m4.start_time)
      expect(m4.lock_version).to eq(@m4.lock_version)
    end
  end

  describe '[20] Extend maintenance' do
    before(:each) do
      Propagation.delete_all
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)

      @m1 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p1.id, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 10800, :allow_test_account => true, :status => 'activated'})
      @m1.save(:validate => false)

      @m2 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p2.id, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 10800, :allow_test_account => true, :status => 'activated'})
      @m2.save(:validate => false)
    end

    after(:each) do
      Propagation.delete_all
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
    end

    it '[20.1] extend maintenance' do
      @time_now = Time.parse("2014-09-18 13:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      #visit '/administration'
      #click_link('Search Maintenance')
      #find('#myTab1').find('a', :text => 'On Going').click
      #click_link("extend_#{@m1.id}")
      visit extend_maintenance_path(@m1)
      click_button I18n.t("general.confirm")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      @m1.reload
      expect(@m1.start_time).to eq('2014-09-18 12:00:00 +0800')
      expect(@m1.end_time).to eq('2014-09-18 15:30:00 +0800')
      expect(@m1.duration).to eq(12600)
      propagations = @m1.propagations
      expect(propagations.length).to eq(1)
      expect(propagations[0].status).to eq('propagating')
      expect(propagations[0].action).to eq('extend')
      expect(current_path).to eq on_going_maintenance_path
    end
    
    it '[20.2] audit log for Extend Maintenance' do
      @time_now = Time.parse("2014-09-18 13:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      #visit '/administration'
      #click_link('Search Maintenance')
      #find('#myTab1').find('a', :text => 'On Going').click
      #visit on_going_maintenance_path
      #click_link("extend_#{@m1.id}")
      visit extend_maintenance_path(@m1)
      click_button I18n.t("general.confirm")
      @m1.reload
      propagations = @m1.propagations
      al = AuditLog.first
      expect(al.audit_target).to eq("maintenance")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("extend")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[20.5] Time validation for extend maintenance - on going tab' do
      @time_now = Time.parse("2014-09-18 14:59:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => 'On Going').click
      @time_now = Time.parse("2014-09-18 15:00:00 UTC")
      Time.stub(:now).and_return(@time_now)
      click_link("extend_#{@m2.id}")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled") 
    end

    it '[20.7] Time validation for extend maintenance - extend page' do
      @time_now = Time.parse("2014-09-18 13:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => 'On Going').click
      click_link("extend_#{@m2.id}")
      @time_now = Time.parse("2014-09-18 15:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      click_button I18n.t("general.confirm")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      m2 = Maintenance.find_by_id(@m2.id)
      expect(m2.end_time).to eq(@m2.end_time)
      expect(m2.lock_version).to eq(@m2.lock_version)
    end
  end
  
  describe '[21] Cancel maintenance' do
    before(:each) do
      Propagation.delete_all
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)

      @m1 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p1.id, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 10800, :allow_test_account => true, :status => 'scheduled'})
      @m1.save(:validate => false)

      @m2 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p2.id, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 10800, :allow_test_account => true, :status => 'scheduled'})
      @m2.save(:validate => false)
    end

    after(:each) do
      Propagation.delete_all
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
    end
    
    it '[21.1] audit log for Cancel Maintenance' do
      @time_now = Time.parse("2014-09-18 10:00:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => I18n.t("maintenance_status.scheduled")).click
      click_link("cancel_#{@m1.id}") 
      @m1.reload
      propagations = @m1.propagations
      al = AuditLog.first
      expect(al.audit_target).to eq("maintenance")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("cancel")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[21.4] Time validation for cancel maintenance' do
      @time_now = Time.parse("2014-09-18 11:59:00")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => I18n.t("maintenance_status.scheduled")).click
      @time_now = Time.parse("2014-09-18 12:00:00")
      Time.stub(:now).and_return(@time_now)
      click_link("cancel_#{@m1.id}")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      m2 = Maintenance.find_by_id(@m2.id)
      expect(m2.status).to eq(@m2.status)
    end
  end

  describe '[22] Complete maintenance' do
    before(:each) do
      Propagation.delete_all
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)

      @m1 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p1.id, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 10800, :allow_test_account => true, :status => 'activated'})
      @m1.save(:validate => false)

      @m2 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => @p2.id, :start_time => '2014-09-18 12:00:00', :end_time => '2014-09-18 15:00:00', :duration => 10800, :allow_test_account => true, :status => 'activated'})
      @m2.save(:validate => false)
    end

    after(:each) do
      Propagation.delete_all
      Maintenance.delete_all
      Property.delete_all
      AuditLog.delete_all
    end
    
    it '[22.1] audit log for Complete Maintenance' do
      @time_now = Time.parse("2014-09-18 13:00:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => 'On Going').click
      click_link("complete_#{@m1.id}") 
      @m1.reload
      propagations = @m1.propagations
      al = AuditLog.first
      expect(al.audit_target).to eq("maintenance")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("complete")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[22.2] Create propagation for complete maintenance' do
      @time_now = Time.parse("2014-09-18 13:00:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => 'On Going').click
      click_link("complete_#{@m1.id}") 
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      @m1.reload
      expect(@m1.status).to eq('completing')
      propagations = @m1.propagations
      expect(propagations.length).to eq(1)
      expect(propagations[0].status).to eq('propagating')
      expect(propagations[0].action).to eq('complete')
      check_flash_message I18n.t("flash_message.success")
    end

    it '[22.3] Allow one active propagation job when complete maintenance' do
      @time_now = Time.parse("2014-09-18 13:00:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => 'On Going').click
      @m1.propagations.create({:action => "extend", :status => "propagating", :propagating_at => '2014-09-18 12:00:10 UTC', :retry => 0})
      click_link("complete_#{@m1.id}") 
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      @m1.reload
      expect(@m1.status).to eq('completing')
      propagations = @m1.propagations
      expect(propagations.length).to eq(1)
      expect(propagations[0].status).to eq('propagating')
      expect(propagations[0].action).to eq('complete')
      check_flash_message I18n.t("flash_message.success")
    end

    it '[22.5] Time validation for complete maintenance' do
      @time_now = Time.parse("2014-09-18 14:59:00 UTC")
      Time.stub(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/administration'
      click_link('Search Maintenance')
      find('#myTab1').find('a', :text => 'On Going').click
      @time_now = Time.parse("2014-09-18 15:00:00 UTC")
      Time.stub(:now).and_return(@time_now)
      click_link("complete_#{@m2.id}")
      expect(page).to have_selector("ul#myTab1 li.active", "Scheduled")
      m2 = Maintenance.find_by_id(@m2.id)
      expect(m2.status).to eq('activated')
      propagations = @m2.propagations
      expect(propagations.length).to eq(0)
      check_flash_message I18n.t("flash_message.time_invalid")
    end
  end
end
