require "rails_helper"

describe CasinosSystemUser do
  fixtures :casinos, :system_users
  
  describe "test get_users_active_casinos" do

    def create_casino_system_users system_user_id, casino_id, status=true
      CasinosSystemUser.create(system_user_id: system_user_id, casino_id: casino_id, status: status)
    end
    
    before(:each) do
      create_casino_system_users(1,1000)
      create_casino_system_users(1,1002)
      create_casino_system_users(1,1003,false)
      create_casino_system_users(3,1000)
    end

  	it "success" do
  	  user_casinos = CasinosSystemUser.get_users_active_casinos
  	  expect(user_casinos.length).to eq 2
      casinos_1 = [{"id"=>1000,"name"=>"fake_casino_1000"}, {"id"=>1002,"name"=>"fake_casino_1002"}]
      expect(user_casinos[1]).to eq casinos_1
      casinos_3 = [{"id"=>1000,"name"=>"fake_casino_1000"}]
      expect(user_casinos[3]).to eq casinos_3
  	end

  	it "casinos_system_user no data" do
  	  CasinosSystemUser.delete_all
  	  user_casinos = CasinosSystemUser.get_users_active_casinos
  	  expect(user_casinos).not_to be_nil
  	  expect(user_casinos.length).to eq 0
  	end
  end
end