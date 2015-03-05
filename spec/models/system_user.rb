require "rails_helper"

describe SystemUser do
  before(:all) do
  end

  after(:all) do
  end

  describe 'activated?' do
    after(:all) do
    end

    it 'should return the activation status properly' do
      sys_u = SystemUser.new(:username => 'test_account', :status => true)
      expect(sys_u.activated?).to eq(true)
    end
  end
end
