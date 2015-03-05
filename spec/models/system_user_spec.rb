require "rails_helper"

describe SystemUser do
  before(:all) do
    @user_manager = Role.find_by_name("user_manager")
    @system_operator = Role.find_by_name("system_operator")
  end

  after(:all) do
  end

  describe 'update_roles' do
    before(:each) do
      @su1 = SystemUser.create!(:username => 'lucy1', :status => true, :admin => false)
      @su2 = SystemUser.create!(:username => 'lucy2', :status => true, :admin => false)
      @su2.role_assignments.create!({:role_id => @user_manager.id})
      @su3 = SystemUser.create!(:username => 'lucy3', :status => true, :admin => false)
      @su3.role_assignments.create!({:role_id => @user_manager.id})
    end

    after(:each) do
      @su1.destroy
      @su2.destroy
      @su3.destroy
      RoleAssignment.delete_all
    end

    it 'should add a new role to a system user with no role' do
      @su1.update_roles(@user_manager.id)
      expect(@su1.role_assignments.length).to eq(1)
      expect(@su1.role_assignments[0].role_id).to eq(@user_manager.id)
    end

    it 'should add change system user role' do
      @su2.update_roles(@system_operator.id) 
      expect(@su2.role_assignments.length).to eq(1)
      expect(@su2.role_assignments[0].role_id).to eq(@system_operator.id)
    end

    it 'should delete the existing role if n/a is selected' do
      @su3.update_roles(-1)
      @su3.reload
      expect(@su3.role_assignments.length).to eq(0)
    end

    it 'should not change the existing role if the same role is selected' do
      @su2.update_roles(@user_manager.id)
      expect(@su2.role_assignments.length).to eq(1)
      expect(@su2.role_assignments[0].role_id).to eq(@user_manager.id)
    end

    it 'should not change no role if no role is selected again' do
      @su1.update_roles(-1)
      expect(@su1.role_assignments.length).to eq(0)
    end
  end
end
