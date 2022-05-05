require "rails_helper"

describe CasinosSystemUser do
  describe "test get_users_active_casinos" do
    def create_licensee(id=1)
      Licensee.create(id: 1, name: "licensee1")
    end

    def create_domain(id=1)
      Domain.create(id: id, name: "test#{id}.laxino.com")
    end

    def create_casinos(casino_ids, licensee_id=1)
      casino_ids.each do |casino_id|
        Casino.create(id: casino_id, name: "fake_casino_#{casino_id}", licensee_id: licensee_id)
      end
    end

    def create_system_users(ids, domain_id=1)
      ids.each do |id|
        SystemUser.create(id: id, username: "user#{id}", domain_id: domain_id)
      end
    end

    def create_casino_system_users system_user_id, casino_id, status=true
      CasinosSystemUser.create(system_user_id: system_user_id, casino_id: casino_id, status: status)
    end
    
    before(:each) do
      create_licensee
      create_domain
      create_casinos([1000, 1002, 1003])
      create_system_users([1, 3])
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