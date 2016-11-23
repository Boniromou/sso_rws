require "rails_helper"

describe Licensee do
	describe "test create domain licensee mapping" do
		def check_create_failed(params)
			flag = false
      begin
        Licensee.create_domain_licensee(params)
      rescue Rigi::CreateDomainLicenseeFail
        flag = true
      end
      expect(flag).to eq true
		end

		before(:each) do
			@domain1 = Domain.create(name: 'domain1.com')
      @domain2 = Domain.create(name: 'domain2.com')
      @licensee1 = Licensee.create(name: '1000')
      @licensee2 = Licensee.create(name: '1003', domain_id: @domain2.id)
      @params = {licensee_id: @licensee1.id, domain_id: @domain1.id}
		end

		it "create domain licensee mapping successfully" do
			expect(@licensee1.domain_id).to eq nil
			Licensee.create_domain_licensee(@params)
			expect(Licensee.find(@licensee1.id).domain_id).to eq @domain1.id
		end

		it "create domain licensee mapping failed: domain or licensee not exist" do
			@params[:licensee_id] = nil
			check_create_failed(@params)
		end

		it "create domain licensee mapping successfully: domain used" do
			@params[:domain_id] = @domain2.id
			Licensee.create_domain_licensee(@params)
			expect(Licensee.find(@licensee1.id).domain_id).to eq @domain2.id
		end

		it "create domain licensee mapping failed: licensee used" do
			@params[:licensee_id] = @licensee2.id
			check_create_failed(@params)
		end
	end

	describe "test delete domain licensee mapping" do
		before(:each) do
			@domain1 = Domain.create(name: 'domain1.com')
      @domain2 = Domain.create(name: 'domain2.com')
      @licensee1 = Licensee.create(name: '1000', domain_id: @domain2.id)
      @params = {licensee_id: @licensee1.id, domain_id: @domain2.id}
		end

		it "delete domain licensee mapping successfully" do
			expect(@licensee1.domain_id).to eq @domain2.id
			Licensee.remove_domain_licensee(@params)
			expect(Licensee.find(@licensee1.id).domain_id).to eq nil
		end

		it "delete domain licensee mapping failed: domain or licensee not exist" do
			@params[:domain_id] = @domain1.id
			flag = false
      begin
        Licensee.remove_domain_licensee(@params)
      rescue Rigi::DeleteDomainLicenseeFail
        flag = true
      end
      expect(flag).to eq true
		end
	end
end