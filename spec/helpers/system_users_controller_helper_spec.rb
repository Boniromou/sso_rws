require 'rails_helper'

describe SystemUsersControllerHelper do
  before(:all) do
    @root_user = SystemUser.find_by_admin(1)
    @user_manager = Role.find_by_name("user_manager")
    @system_operator = Role.find_by_name("system_operator")
  end

  after(:all) do
  end

  describe 'system_user_status_format' do
    it 'should return active for system user status true' do
      result = helper.system_user_status_format(true)
      expect(result).to eq("user.active")
    end

    it 'should return inactive for system user status false' do
      result = helper.system_user_status_format(false)
      expect(result).to eq("user.inactive")
    end

    it 'should return inactive for system user status nil' do
      result = helper.system_user_status_format(nil)
      expect(result).to eq("user.inactive")
    end
  end

  describe 'change_status_button_name' do
    it 'should return lock if status is true' do
      result = helper.change_status_button_name(true)
      expect(result).to eq("user.lock")
    end

    it 'should return unlock if status is false' do
      result = helper.change_status_button_name(false)
      expect(result).to eq("user.unlock")
    end

    it 'should return unlock if status is nil' do
      result = helper.change_status_button_name(nil)
      expect(result).to eq("user.unlock")
    end
  end

  describe 'roles_format' do
    before(:each) do
      @su1 = SystemUser.create!(:username => 'lucy', :status => true, :admin => false)
      @su2 = SystemUser.create!(:username => 'lucy2', :status => true, :admin => false)
      @su2.role_assignments.create!({:role_id => @user_manager.id}) 
    end
 
    after(:each) do
      @su1.destroy
      @su2.destroy
      RoleAssignment.delete_all
    end

    it 'should return root user if system user is root user' do
      result = helper.roles_format(@root_user)
      expect(result).to eq("role.root_user")
    end

    it 'should return na if system user is has no role' do
      result = helper.roles_format(@su1)
      expect(result).to eq("general.na")
    end

    it 'should return role name if system user has role' do
      result = helper.roles_format(@su2)
      expect(result).to eq("role.#{@user_manager.name}")
    end
  end

  describe 'disable_lock_button?' do
    before(:each) do
      @su1 = SystemUser.create!(:username => 'lucy', :status => true, :admin => false)
    end

    after(:each) do
      @su1.destroy
    end

    it 'should disable lock/unlock button for root user' do
      result = helper.disable_lock_button?(@root_user)
      expect(result).to eq(true)
    end

    it 'should disable lock/unlock button for current user himself' do
      allow(helper).to receive(:current_system_user).and_return(@su1)
      result = helper.disable_lock_button?(@su1)
      expect(result).to eq(true)
    end

    it 'should not disable lock/unlock button for non-current user' do
      allow(helper).to receive(:current_system_user).and_return(@root_user)
      result = helper.disable_lock_button?(@su1)
      expect(result).to eq(false)
    end
  end

  describe 'disable_edit_roles_button?' do
    before(:each) do
      @su1 = SystemUser.create!(:username => 'lucy', :status => true, :admin => false)
    end

    after(:each) do
      @su1.destroy
    end

    it 'should disable edit roles button for root user' do
      result = helper.disable_edit_roles_button?(@root_user)
      expect(result).to eq(true)
    end
   
    it 'should disable edit roles button for current user himself' do
      allow(helper).to receive(:current_system_user).and_return(@su1)
      result = helper.disable_edit_roles_button?(@su1)
      expect(result).to eq(true)
    end

    it 'should not disable edit roles button for non-current user' do
      allow(helper).to receive(:current_system_user).and_return(@root_user)
      result = helper.disable_edit_roles_button?(@su1)
      expect(result).to eq(false)
    end
  end

  describe 'current_role?' do
    before(:each) do
      @su1 = SystemUser.create!(:username => 'lucy', :status => true, :admin => false)
      @su1.role_assignments.create!({:role_id => @user_manager.id})
      @su2 = SystemUser.create!(:username => 'lucy1', :status => true, :admin => false)
    end

    after(:each) do
      @su1.destroy
      @su2.destroy
    end

    it 'should be true if this role user current role' do
      result = helper.current_role?(@su1, @user_manager.id)
      expect(result).to eq(true)
    end

    it 'should be false if the user has no role' do
      result = helper.current_role?(@su2, @user_manager.id)
      expect(result).to eq(false)
    end

    it 'should be false if not user current role' do
      result = helper.current_role?(@su1, @system_operator.id)
      expect(result).to eq(false)
    end
  end
end
