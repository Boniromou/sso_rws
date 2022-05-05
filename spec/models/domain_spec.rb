require "rails_helper"

describe Domain do
	describe "test insert domain" do
		def check_create_failed(domain=@domain, auth_source=@auth_source_detail)
			flag = false
			domain_count = Domain.count
			auth_source_count = AuthSourceDetail.count
      begin
        Domain.insert(domain, auth_source)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        flag = true
      end
      expect(flag).to eq true
      expect(Domain.count).to eq domain_count
			expect(AuthSourceDetail.count).to eq auth_source_count
		end

		before(:each) do
      @domain = {:name => "example.com"}
      @auth_source_detail = {
	      'name' => 'hqidc_ldap',
	      'data' => {
		      'host' => '0.0.0.0',
		      'port' => '3268',
		      'account' => 'test@example.com',
		      'account_password' => 'cccccc',
		      'base_dn' => 'dc=example, dc=com',
		      'admin_account' => 'admin@example.com',
		      'admin_password' => 'dddddd'
		    }
      }
		end

		it "create domain, ldap successfully" do
			@domain[:name] = '  Example.com  '
			@auth_source_detail['name'] = '  hqidc_ldap  '
			Domain.insert(@domain, @auth_source_detail)
			expect(Domain.exists?(name: @domain[:name].strip.downcase)).to eq true
			@auth_source_detail['name'] = @auth_source_detail['name'].strip
			expect(AuthSourceDetail.exists?(name: @auth_source_detail['name'])).to eq true
		end

		it "create domain, ldap failed: domain format error" do
			@domain[:name] = nil
			check_create_failed

			@domain[:name] = 'test'
			check_create_failed

			@domain[:name] = '.local'
			check_create_failed
		end

		it "create domain, ldap failed: domain duplicated" do
			Domain.create(@domain)
			check_create_failed
		end

		it "create domain, ldap failed: auth_source attributes is null" do
			@auth_source_detail['name'] = nil
			check_create_failed
		end

		it "create domain, ldap failed: ldap duplicated" do
			AuthSourceDetail.create(@auth_source_detail)
			check_create_failed
		end
	end

	describe "test edit domain" do
		def check_update_failed(auth_source_data)
			auth_source_name = auth_source_data['name']
			flag = false
      begin
        @domain1.edit(auth_source_data)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        flag = true
      end
      expect(flag).to eq true
			expect(AuthSourceDetail.exists?(name: @auth_source_data['name'])).to eq true
			expect(AuthSourceDetail.exists?(name: auth_source_name)).to eq false unless auth_source_name == @auth_source_data['name']
		end

		before(:each) do
      @auth_source_data = {
	      'name' => 'hqidc_ldap',
	      'data' => {
		      'host' => '0.0.0.0',
		      'port' => '3268',
		      'account' => 'test@example.com',
		      'account_password' => 'cccccc',
		      'base_dn' => 'dc=example, dc=com',
		      'admin_account' => 'admin@example.com',
		      'admin_password' => 'dddddd'
		    }
      }

      @auth_source_detail = AuthSourceDetail.create(@auth_source_data)
      @auth_source_data['id'] = @auth_source_detail.id
			@domain1 = Domain.create(name: 'domain1.com', auth_source_detail_id: @auth_source_detail.id)
      @domain2 = Domain.create(name: 'domain2.com')
		end

		it "edit domain, ldap successfully" do
			auth_source_data = @auth_source_data.clone
			auth_source_data['name'] = 'test_ldap'
			@domain1.edit(auth_source_data)
			expect(AuthSourceDetail.exists?(name: @auth_source_data['name'])).to eq false
			expect(AuthSourceDetail.exists?(name: 'test_ldap')).to eq true
		end

		it "edit domain, ldap successfully: domain has not auth_source_detail" do
			@auth_source_data.delete(:id)
			@auth_source_data['name'] = 'test_ldap'
			@domain2.edit(@auth_source_data)
			auth_source_detail = AuthSourceDetail.where(name: 'test_ldap')
			@domain2.reload
			expect(@domain2.auth_source_detail_id).to eq auth_source_detail.first.id
			expect(auth_source_detail.count).to eq 1
		end

		it "edit domain, ldap failed: auth_source_detail attributes is null" do
			auth_source_data = @auth_source_data.clone
			auth_source_data['name'] = nil
			check_update_failed(auth_source_data)
		end

		it "eidt domain, ldap failed: ldap duplicated" do
			@auth_source_data.delete(:id)
			@auth_source_data['name'] = "test_ldap"
			AuthSourceDetail.create(@auth_source_data)
			
			auth_source = @auth_source_data.clone
			check_update_failed(auth_source)
		end
	end
end