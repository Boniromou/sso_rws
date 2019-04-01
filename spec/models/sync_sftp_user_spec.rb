require "rails_helper"

describe CsvUserService do
  describe 'Conjob for sync sftp user' do
    def sync_user_info(data)
      CsvUserService.new(@licensee).process_csv('systemuser_20180323174814.csv', data)
    end

    def mock_user_data(count = 1, domain_name = nil)
      rst = []
      count.times.each do |idx|
        rst << ["user#{idx}", domain_name || @domain.name]
      end
      rst
    end

    def check_result(user, status)
      user.reload
      expect(user.status).to eq status
      expect(@licensee.sync_user_data['last_synced_file']).to eq 'systemuser_20180323174814.csv'
    end

    before(:each) do
      @domain = Domain.create(:name => 'example.com')
      @licensee = Licensee.create(:name => 'laxino')
      DomainLicensee.create(domain_id: @domain.id, licensee_id: @licensee.id)
      @role = Role.create!(name: 'user_manager')
    end

    it 'user in file, is active in db, with role, no change' do
      user = SystemUser.create!(:username => 'user0', :status => 'active', :admin => false, domain_id: @domain.id)
      user.role_assignments.create!({:role_id => @role.id})
      sync_user_info(mock_user_data)
      check_result(user, 'active')
    end

    it 'user in file, is active in db, without role, no change' do
      user = SystemUser.create!(:username => 'user0', :status => 'active', :admin => false, domain_id: @domain.id)
      sync_user_info(mock_user_data)
      check_result(user, 'active')
    end

    it 'user in file, is inactive in db, with role, update status to active' do
      user = SystemUser.create!(:username => 'user0', :status => 'inactive', :admin => false, domain_id: @domain.id)
      user.role_assignments.create!({:role_id => @role.id})
      sync_user_info(mock_user_data)
      check_result(user, 'active')
    end

    it 'user in file, is inactive in db, without role, no change' do
      user = SystemUser.create!(:username => 'user0', :status => 'inactive', :admin => false, domain_id: @domain.id)
      sync_user_info(mock_user_data)
      check_result(user, 'inactive')
    end

    it 'user not in file, is active in db, with role, no change' do
      user = SystemUser.create!(:username => 'user1', :status => 'active', :admin => false, domain_id: @domain.id)
      user.role_assignments.create!({:role_id => @role.id})
      sync_user_info(mock_user_data)
      check_result(user, 'active')
    end

    it 'user not in file, is active in db, without role, update status to inactive' do
      user = SystemUser.create!(:username => 'user1', :status => 'active', :admin => false, domain_id: @domain.id)
      sync_user_info(mock_user_data)
      check_result(user, 'inactive')
    end

    it 'user not in file, is inactive in db, with role, update status to active' do
      user = SystemUser.create!(:username => 'user1', :status => 'inactive', :admin => false, domain_id: @domain.id)
      user.role_assignments.create!({:role_id => @role.id})
      sync_user_info(mock_user_data)
      check_result(user, 'active')
    end

    it 'user not in file, is inactive in db, without role, no change' do
      user = SystemUser.create!(:username => 'user1', :status => 'inactive', :admin => false, domain_id: @domain.id)
      sync_user_info(mock_user_data)
      check_result(user, 'inactive')
    end

    it 'user in file, is pending in db, no change' do
      user = SystemUser.create!(:username => 'user0', :status => 'pending', :admin => false, domain_id: @domain.id)
      sync_user_info(mock_user_data)
      check_result(user, 'pending')
    end

    it 'user in file, is not in db, no change' do
      sync_user_info(mock_user_data)
      expect(SystemUser.where(username: 'user0').count).to eq 0
    end

    it 'wrong domain data, no change' do
      sync_user_info(mock_user_data(1, 'wrong.com'))
      expect(SystemUser.where(username: 'user0').count).to eq 0
    end
  end
end
