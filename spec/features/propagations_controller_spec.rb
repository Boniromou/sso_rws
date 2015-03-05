require "feature_spec_helper"

describe PropagationsController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = SystemUser.find_by_admin(1)
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[28] Resume Propagation' do
    before(:each) do
      Propagation.delete_all
      Maintenance.delete_all
      Property.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @p1 = Property.create!(:id => 1003)
      @p2 = Property.create!(:id => 1007)
      @m1 = Maintenance.new({:maintenance_type_id => @mt1.id, :property_id => 1007, :start_time => '2014-09-18 12:00:00 UTC', :end_time => '2014-09-18 15:00:00 UTC', :duration => 18000, :allow_test_account => true, :status => 'activating'})
      @m1.save(:validate => false)
      @m1.propagations.create({:action => "activate", :status => "broken", :propagating_at => '2014-09-18 12:00:10 UTC', :retry => 3})
    end

    after(:each) do
      Propagation.delete_all
      Maintenance.delete_all
      Property.delete_all
    end
    
    it '[28.1] Resume propagation' do
      @time_now = Time.parse("2014-09-18 13:00:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit '/search_maintenance/list_on_going_maintenance'
      #click_link I18n.t("tree_view.search_maintenance")
      #find('#myTab1').find('a', :text => I18n.t("maintenance.on_going")).click
      click_button("resume_#{@m1.propagations.first.id}")
      @m1.reload
      propagations = @m1.propagations
      expect(propagations.length).to eq(1)
      expect(propagations[0].status).to eq('propagating')
      expect(current_path).to eq(on_going_maintenance_path)
    end

    it '[28.2] Time validation for resume propagation' do
      @time_now = Time.parse("2014-09-18 14:59:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit on_going_maintenance_path
      @time_now = Time.parse("2014-09-18 15:00:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      click_button("resume_#{@m1.propagations.first.id}")
      @m1.reload
      propagations = @m1.propagations
      expect(propagations.length).to eq(1)
      expect(propagations[0].action).to eq("activate")
      expect(propagations[0].status).to eq("broken")
      expect(current_path).to eq(on_going_maintenance_path)
      check_flash_message I18n.t("flash_message.time_invalid")
    end

    it '[28.3] audit log for resume propagation' do
      @time_now = Time.parse("2014-09-18 13:00:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit on_going_maintenance_path
      click_button("resume_#{@m1.propagations.first.id}")
      @m1.reload
      propagations = @m1.propagations
      expect(propagations.length).to eq(1)
      expect(propagations[0].status).to eq('propagating')
      expect(current_path).to eq(on_going_maintenance_path)
      al = AuditLog.first
      expect(al.audit_target).to eq("propagation")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("resume")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[28.4] Lock version control for resume propagation' do
      @time_now = Time.parse("2014-09-18 13:00:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      allow_any_instance_of(Propagation).to receive(:resume).and_raise(ActiveRecord::StaleObjectError.new(Propagation, :resume))
      login_as(@root_user, :scope => :system_user)
      visit on_going_maintenance_path
      click_button("resume_#{@m1.propagations.first.id}")
      @m1.reload
      propagations = @m1.propagations
      expect(propagations.length).to eq(1)
      expect(propagations[0].action).to eq("activate")
      expect(propagations[0].status).to eq("broken")
      expect(current_path).to eq(on_going_maintenance_path)
      check_flash_message I18n.t("flash_message.lock_error")
    end

    it '[28.5] audit log for resume propagation fail case (lock version)' do
      @time_now = Time.parse("2014-09-18 14:59:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      #allow_any_instance_of(Propagation).to receive(:resume).and_raise(ActiveRecord::StaleObjectError.new(Propagation, :resume))
      login_as(@root_user, :scope => :system_user)
      visit on_going_maintenance_path
      m1 = Maintenance.find_by_id(@m1.id)
      m1.propagations.first.update_attribute :propagating_at, '2014-09-18 12:00:11 UTC'
      click_button("resume_#{@m1.propagations.first.id}")
      @m1.reload
      #propagations = @m1.propagations
      #expect(propagations.length).to eq(1)
      #expect(propagations[0].action).to eq("activate")
      #expect(propagations[0].status).to eq("broken")
      #expect(current_path).to eq(on_going_maintenance_path)
      check_flash_message I18n.t("flash_message.lock_error")
      al = AuditLog.first
      expect(al.audit_target).to eq("propagation")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("resume")
      expect(al.action_status).to eq("fail")
      expect(al.action_error).not_to be_empty
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end

    it '[28.6] audit log for resume propagation fail case (time invalid)' do
      @time_now = Time.parse("2014-09-18 14:59:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      login_as(@root_user, :scope => :system_user)
      visit on_going_maintenance_path
      @time_now = Time.parse("2014-09-18 15:00:00 UTC")
      allow(Time).to receive(:now).and_return(@time_now)
      click_button("resume_#{@m1.propagations.first.id}")
      @m1.reload
      propagations = @m1.propagations
      expect(propagations.length).to eq(1)
      expect(propagations[0].action).to eq("activate")
      expect(propagations[0].status).to eq("broken")
      expect(current_path).to eq(on_going_maintenance_path)
      check_flash_message I18n.t("flash_message.time_invalid")
      al = AuditLog.first
      expect(al.audit_target).to eq("propagation")
      expect(al.action_type).to eq("update")
      expect(al.action).to eq("resume")
      expect(al.action_status).to eq("fail")
      expect(al.action_error).not_to be_empty
      expect(al.session_id).not_to be_empty
      expect(al.ip).not_to be_empty
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end
  end
end
