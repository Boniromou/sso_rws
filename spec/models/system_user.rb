require "rails_helper"

describe SystemUser do
  
  before(:each) do
    AuthSource.create(:auth_type => "AuthSourceLdap", :name => "Laxino LDAP",:host => "0.0.0.0", :port => 389, :account => "", :account_password => "", :base_dn => "DC=test,DC=example,DC=com") 
    domain = Domain.create(:name => 'example.com') 
    licensee = Licensee.create(:name => 'laxino') 
    [1000, 1003, 1007].each do |casino|
      Casino.create(:id => casino, :name => casino, :licensee_id => licensee.id)
      DomainsCasino.create(:domain_id => domain.id, :casino_id => casino)
    end
  end

  after(:each) do
    DomainsCasino.delete_all
    Casino.delete_all
    Licensee.delete_all
    Domain.delete_all
    AuthSource.delete_all
  end

  describe '[26] Conjob for updating system user status and casino group' do
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
end
