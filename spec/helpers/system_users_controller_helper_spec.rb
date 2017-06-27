require 'rails_helper'

describe SystemUsersControllerHelper do
  before(:each) do
    @root_user = create(:system_user, :admin, :with_casino_ids => [1000])
    app = create(:app, name: APP_NAME)   
    @user_manager = create(:role, name: "user_manager", app_id: app.id)
    @system_auditor = create(:role, name: "system_auditor", app_id: app.id)
  end

  describe 'system_user_status_format' do
    it 'should return active for system user status true' do
      result = helper.system_user_status_format('active')
      expect(result).to eq t("user.active")
    end

    it 'should return inactive for system user status false' do
      result = helper.system_user_status_format('inactive')
      expect(result).to eq t("user.inactive")
    end

    it 'should return nil for system user status nil' do
      result = helper.system_user_status_format(nil)
      expect(result).to be_nil
    end
  end

  describe 'roles_format' do
    before(:each) do
      @su1 = SystemUser.create!(:username => 'lucy', :status => 'active', :admin => false)
      @su2 = SystemUser.create!(:username => 'lucy2', :status => 'active', :admin => false)
      @su2.role_assignments.create!({:role_id => @user_manager.id}) 
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

  # describe 'disable_lock_button?' do
  #   before(:each) do
  #     @su1 = SystemUser.create!(:username => 'lucy', :status => true, :admin => false)
  #   end

  #   it 'should disable lock/unlock button for root user' do
  #     result = helper.disable_lock_button?(@root_user)
  #     expect(result).to eq(true)
  #   end

  #   it 'should disable lock/unlock button for current user himself' do
  #     allow(helper).to receive(:current_system_user).and_return(@su1)
  #     result = helper.disable_lock_button?(@su1)
  #     expect(result).to eq(true)
  #   end

  #   it 'should not disable lock/unlock button for non-current user' do
  #     allow(helper).to receive(:current_system_user).and_return(@root_user)
  #     result = helper.disable_lock_button?(@su1)
  #     expect(result).to eq(false)
  #   end
  # end

  # describe 'disable_edit_roles_button?' do
  #   before(:each) do
  #     @su1 = SystemUser.create!(:username => 'lucy', :status => true, :admin => false)
  #   end

  #   it 'should disable edit roles button for root user' do
  #     result = helper.disable_edit_roles_button?(@root_user)
  #     expect(result).to eq(true)
  #   end
   
  #   it 'should disable edit roles button for current user himself' do
  #     allow(helper).to receive(:current_system_user).and_return(@su1)
  #     result = helper.disable_edit_roles_button?(@su1)
  #     expect(result).to eq(true)
  #   end

  #   it 'should not disable edit roles button for non-current user' do
  #     allow(helper).to receive(:current_system_user).and_return(@root_user)
  #     result = helper.disable_edit_roles_button?(@su1)
  #     expect(result).to eq(false)
  #   end
  # end

  describe 'current_role?' do
    before(:each) do
      @su1 = SystemUser.create!(:username => 'lucy', :status => true, :admin => false)
      @su1.role_assignments.create!({:role_id => @user_manager.id})
      @su2 = SystemUser.create!(:username => 'lucy1', :status => true, :admin => false)
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
      result = helper.current_role?(@su1, @system_auditor.id)
      expect(result).to eq(false)
    end
  end
end
