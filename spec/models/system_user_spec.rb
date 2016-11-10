require "rails_helper"

describe SystemUser do
  before(:each) do
    AppSystemUser.delete_all
    CasinosSystemUser.delete_all
    SystemUser.delete_all
    Casino.delete_all
    Domain.delete_all
    Licensee.delete_all
    AuthSource.delete_all
  end

  describe '[26] Conjob for updating system user status and casino group' do
    before(:each) do
      auth_source = AuthSource.create(:auth_type => "AuthSourceLdap", :name => "Laxino LDAP",:host => "0.0.0.0", :port => 389, :account => "", :account_password => "", :base_dn => "DC=test,DC=example,DC=com") 
      licensee = Licensee.create(:name => 'laxino', :auth_source_id => auth_source.id) 
      domain = Domain.create(:name => 'example.com', :licensee_id => licensee.id) 
      [1000, 1003, 1007].each do |casino|
        Casino.create(:id => casino, :name => casino, :licensee_id => licensee.id)
      end
    end
  
    def mock_ldap_query(account_status, casino_ids)
      dn = account_status ? ["OU=Licensee"] : ["OU=Licensee,OU=Disabled Accounts"]
      memberof = casino_ids.map { |casino_id| "CN=#{casino_id}casinoid" }
      entry = [{ :distinguishedName => dn, :memberOf => memberof }]
      allow_any_instance_of(AuthSourceLdap).to receive(:search).and_return(entry)
    end

    def mock_ad_account_profile(status, casino_ids)
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      mock_ldap_query(status, casino_ids)
    end

    def regist_and_return_system_user(username, domain)
      SystemUser.register_account!(username, domain)
      system_user = SystemUser.find_by_username(username)
      system_user.cache_profile
      return system_user
    end

    it '[26.1] active user updated to inactive' do
      mock_ad_account_profile(false, [1003])
      system_user = regist_and_return_system_user('test', 'example.com')
      cache_info = Rails.cache.read(system_user.id)
      expect(system_user.status).to eq true  
      expect(cache_info[:status]).to eq true

      SystemUser.sync_user_info

      system_user = SystemUser.find_by_username('test')
      cache_info = Rails.cache.read(system_user.id)
      expect(system_user.status).to eq false    
      expect(cache_info[:status]).to eq false 
    end

    it '[26.2] user casino group change' do
      mock_ad_account_profile(true, [1003])
      system_user = regist_and_return_system_user('test', 'example.com')
      cache_info = Rails.cache.read(system_user.id)
      expect(system_user.active_casino_ids).to eq [1003]
      expect(cache_info[:casinos]).to eq [1003]

      mock_ad_account_profile(true, [1007])
      SystemUser.sync_user_info

      system_user = SystemUser.find_by_username('test')
      cache_info = Rails.cache.read(system_user.id)
      expect(system_user.active_casino_ids).to eq [1007]      
      expect(cache_info[:casinos]).to eq [1007]
    end
  end

  describe 'update_roles' do
    fixtures :roles, :apps

    before(:each) do
      @user_manager = Role.find_by_name("user_manager")
      @cashier = Role.find_by_name("cashier")
      @su1 = SystemUser.create!(:username => 'lucy1', :status => true, :admin => false)
      @su2 = SystemUser.create!(:username => 'lucy2', :status => true, :admin => false)
      @su2.role_assignments.create!({:role_id => @user_manager.id})
      @su2.app_system_users.create!({:app_id => @user_manager.app_id})
      @su3 = SystemUser.create!(:username => 'lucy3', :status => true, :admin => false)
      @su3.role_assignments.create!({:role_id => @user_manager.id})
      @su3.app_system_users.create!({:app_id => @user_manager.app_id})
    end

    after(:each) do
      AppSystemUser.delete_all
      RoleAssignment.delete_all
      @su1.destroy
      @su2.destroy
      @su3.destroy
    end

    it 'should add a new role to a system user with no role' do
      @su1.update_roles([@user_manager.id])
      @su1.reload
      expect(@su1.role_assignments.length).to eq(1)
      expect(@su1.role_assignments[0].role_id).to eq(@user_manager.id)
    end

    it 'should add change system user role' do
      @su2.update_roles([@cashier.id])
      @su2.reload
      expect(@su2.role_assignments.length).to eq(1)
      expect(@su2.role_assignments[0].role_id).to eq(@cashier.id)
    end

    # it 'should delete the existing role if n/a is selected' do
    #   @su3.update_roles([-1])
    #   @su3.reload
    #   expect(@su3.role_assignments.length).to eq(0)
    # end

    it 'should not change the existing role if the same role is selected' do
      @su2.update_roles([@user_manager.id])
      @su2.reload
      expect(@su2.role_assignments.length).to eq(1)
      expect(@su2.role_assignments[0].role_id).to eq(@user_manager.id)
    end

    # it 'should not change no role if no role is selected again' do
    #   @su1.update_roles([-1])
    #   @su1.reload
    #   expect(@su1.role_assignments.length).to eq(0)
    # end
  end
end
