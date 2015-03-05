require "rails_helper"

describe Maintenance do
  before(:all) do
    Maintenance.delete_all
    Property.delete_all

    @p1 = Property.create!(:id => 1003)
    @p2 = Property.create!(:id => 1007)
  end

  after(:all) do
    Maintenance.delete_all
    Property.delete_all
  end

  describe 'self.scheduled' do
    before(:each) do
      @mt1 = MaintenanceType.find_by_name("per_game") 
      @m1 = Maintenance.create!(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:00:00', :end_time => '2014-10-15 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'scheduled')
      @m2 = Maintenance.create!(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-16 10:00:00', :end_time => '2014-10-16 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'cancelled')
    end

    after(:each) do
      Maintenance.delete_all
    end

    it 'should return the scheduled maintenance' do
      @time_now = Time.parse("2014-10-15 09:00:00")
      Time.stub(:now).and_return(@time_now)
      results = Maintenance.scheduled
      expect(results.length).to eq(1)
    end
  end

  describe 'self.on_going' do
    before(:each) do
      @mt1 = MaintenanceType.find_by_name("per_game")
      @m1 = Maintenance.create!(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:00:00', :end_time => '2014-10-15 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'activated')
      @m2 = Maintenance.create!(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-16 10:00:00', :end_time => '2014-10-16 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'cancelled')
    end

    after(:each) do
      Maintenance.delete_all
    end

    it 'should return the scheduled maintenance' do
      @time_now = Time.parse("2014-10-15 18:01:00")
      Time.stub(:now).and_return(@time_now)
      results = Maintenance.on_going
      expect(results.length).to eq(1)
    end
  end

  describe 'too_early_start_time' do
    before(:each) do
      @mt1 = MaintenanceType.find_by_name("per_game")
    end

    after(:each) do
      Maintenance.delete_all
    end

    it 'should add error if maintenance start too early' do
      @time_now = Time.parse("2014-10-15 18:00:00")
      Time.stub(:now).and_return(@time_now)
      maintenance = Maintenance.new(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 09:00:00', :end_time => '2014-10-15 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'scheduled')
      results = maintenance.too_early_start_time
      expect(results[0]).to eq(I18n.t('alert.invalid_time_range'))
    end
    
    it 'should not add error if maintenance start later than now' do
      @time_now = Time.parse("2014-10-15 17:00:00")
      Time.stub(:now).and_return(@time_now)
      maintenance = Maintenance.new(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:00:00', :end_time => '2014-10-15 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'scheduled')
      results = maintenance.too_early_start_time
      expect(results).to eq(nil)
    end
  end

  describe 'duplicate_maintenance' do
    before(:each) do
      Maintenance.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @m1 = Maintenance.create!(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:00:00', :end_time => '2014-10-15 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'activated')
    end

    after(:each) do
      Maintenance.delete_all
    end

    it 'should add error if maintenance is duplicated' do
      @time_now = Time.parse("2014-10-15 18:01:00")
      Time.stub(:now).and_return(@time_now)
      maintenance = Maintenance.new(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 09:00:00', :end_time => '2014-10-15 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'scheduled')
      maintenance.duplicate_maintenance
      errors = maintenance.errors.messages
      expect(errors[:start_time][0]).to eq(I18n.t('alert.time_conflict', {:maintenance_id => @m1[:id]}))
    end

    it 'should not add error if not duplicated' do
      @time_now = Time.parse("2014-10-15 18:01:00")
      Time.stub(:now).and_return(@time_now)
      maintenance = Maintenance.new(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:30:00', :end_time => '2014-10-15 11:00:00', :duration => 1800, :allow_test_account => true, :status => 'scheduled')
      maintenance.duplicate_maintenance
      expect(maintenance.errors.messages).to eq({})
    end

    it 'should not check duplicate on self' do
      @time_now = Time.parse("2014-10-15 18:01:00")
      Time.stub(:now).and_return(@time_now)
      maintenance = Maintenance.find_by_id(@m1[:id])
      maintenance.duplicate_maintenance
      expect(maintenance.errors.messages).to eq({})
    end
  end

  describe 'overlaps?' do
    before(:each) do
      Maintenance.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @m1 = Maintenance.create!(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:00:00', :end_time => '2014-10-15 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'activated')
    end

    after(:each) do
      Maintenance.delete_all
    end

    it 'should return true if time overlap' do
      @time_now = Time.parse("2014-10-15 18:01:00")
      Time.stub(:now).and_return(@time_now)
      maintenance = Maintenance.new(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 09:00:00', :end_time => '2014-10-15 10:30:00', :duration => 1800, :allow_test_account => true, :status => 'scheduled')
      expect(maintenance.overlaps?(@m1)).to eq(true)
    end

    it 'should return false if time does not overlap' do
      @time_now = Time.parse("2014-10-15 18:01:00")
      Time.stub(:now).and_return(@time_now)
      maintenance = Maintenance.new(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:30:00', :end_time => '2014-10-15 11:00:00', :duration => 1800, :allow_test_account => true, :status => 'scheduled')
      expect(maintenance.overlaps?(@m1)).to eq(false)
    end
  end

  describe 'is_never_end?' do
    before(:each) do
      Maintenance.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @m1 = Maintenance.create!(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:00:00', :end_time => '2999-01-02 10:30:00', :duration => 0, :allow_test_account => true, :status => 'scheduled')
      @m2 = Maintenance.create!(:property_id => 1007, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:00:00', :end_time => '2014-10-15 11:00:00', :duration => 0, :allow_test_account => true, :status => 'scheduled')
    end

    after(:each) do
      Maintenance.delete_all
    end

    it 'should return true if it is neverend' do
      time_now = Time.parse("2014-10-15 18:01:00")
      Time.stub(:now).and_return(@time_now)
      expect(@m1.is_never_end?).to eq(true)
    end

    it 'should return false if it is not neverend' do
      time_now = Time.parse("2014-10-15 18:01:00")
      Time.stub(:now).and_return(@time_now)
      expect(@m2.is_never_end?).to eq(false)
    end
  end

  describe 'extend' do
    before(:each) do
      Propagation.delete_all
      Maintenance.delete_all
      @mt1 = MaintenanceType.find_by_name("per_game")
      @m1 = Maintenance.create!(:property_id => 1003, :maintenance_type_id => @mt1[:id], :start_time => '2014-10-15 10:00:00', :end_time => '2999-01-02 10:30:00', :duration => 0, :allow_test_account => true, :status => 'scheduled')
    end

    after(:each) do
      Propagation.delete_all
      Maintenance.delete_all
    end

    it 'should save the extended maintenance and create a propagation job' do
      @m1.extend
      results = @m1.propagations
      expect(results.length).to eq(1)
    end

    it 'should roll back the saved maintenance and not create propagation if save failed' do
      Propagation.stub(:create).and_raise(Exception)
      @m1.extend
      results = @m1.propagations
#      expect(results.length).to eq(0)
    end
  end
end
