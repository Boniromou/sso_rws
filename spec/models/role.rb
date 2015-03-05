require "rails_helper"

describe Role do
  before(:all) do
  end
 
  after(:all) do
  end

  describe 'preset_roles' do
    it 'should return the pre-set roles' do
      roles = Role.all
      expect(roles.length).to eq(5)
      expect(roles[0][:name]).to eq('user_manager')
      expect(roles[1][:name]).to eq('system_operator')
      expect(roles[2][:name]).to eq('helpdesk')
      expect(roles[3][:name]).to eq('property_operator')
      expect(roles[4][:name]).to eq('auditor')
    end
  end
end
