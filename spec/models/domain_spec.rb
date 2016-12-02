require "rails_helper"

describe Domain do
	describe "test insert domain" do
		def check_create_failed(domain=@domain, auth_source=@auth_source)
			flag = false
			domain_count = Domain.count
			auth_source_count = AuthSource.count
      begin
        Domain.insert(domain, auth_source)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        flag = true
      end
      expect(flag).to eq true
      expect(Domain.count).to eq domain_count
			expect(AuthSource.count).to eq auth_source_count
		end

		before(:each) do
      @domain = {:name => "example.com"}
      @auth_source = {
	      :name => "hqidc_ldap",
	      :host => "0.0.0.0",
	      :port => "3268",
	      :account => "test@example.com",
	      :account_password => "cccccc",
	      :base_dn => "dc=example, dc=com",
	      :admin_account => "admin@example.com",
	      :admin_password => "dddddd"
      }
		end

		it "create domain, ldap successfully" do
			@domain[:name] = '  Example.com  '
			@auth_source[:name] = '  hqidc_ldap  '
			Domain.insert(@domain, @auth_source)
			expect(Domain.exists?(name: @domain[:name].strip.downcase)).to eq true
			@auth_source[:name] = @auth_source[:name].strip
			expect(AuthSource.exists?(@auth_source)).to eq true
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
			attributes = [:name, :host, :port, :account, :account_password, :base_dn, :admin_account, :admin_password]
			attributes.each do |attribute|
				auth_source = @auth_source.clone
				auth_source[attribute] = nil
				check_create_failed(@domain, auth_source)
			end
		end

		it "create domain, ldap failed: ldap duplicated" do
			auth_source = @auth_source.clone
			auth_source[:name] = "hqidc_ldap"
			auth_source[:auth_type] = "AuthSourceLdap"
			AuthSource.create(auth_source)
			check_create_failed
		end
	end

	describe "test edit domain" do
		def check_update_failed(auth_source_data)
			flag = false
      begin
        @domain1.edit(auth_source_data)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        flag = true
      end
      expect(flag).to eq true
			expect(AuthSource.exists?(@auth_source_data)).to eq true
			expect(AuthSource.exists?(auth_source_data)).to eq false
		end

		before(:each) do
			@auth_source_data = {
	      :name => "hqidc_ldap",
	      :host => "0.0.0.0",
	      :port => "3268",
	      :account => "test@example.com",
	      :account_password => "cccccc",
	      :base_dn => "dc=example, dc=com",
	      :admin_account => "admin@example.com",
	      :admin_password => "dddddd"
      }

      @auth_source = AuthSource.create(@auth_source_data)
      @auth_source_data[:id] = @auth_source.id
			@domain1 = Domain.create(name: 'domain1.com', auth_source_id: @auth_source.id)
      @domain2 = Domain.create(name: 'domain2.com')
		end

		it "edit domain, ldap successfully" do
			auth_source_data = @auth_source_data.clone
			auth_source_data[:name] = 'test_ldap'
			@domain1.edit(auth_source_data)
			expect(AuthSource.exists?(@auth_source_data)).to eq false
			expect(AuthSource.exists?(auth_source_data)).to eq true
		end

		it "edit domain, ldap successfully: domain has not auth_source" do
			@auth_source_data.delete(:id)
			@auth_source_data[:name] = 'test_ldap'
			@domain2.edit(@auth_source_data)
			auth_source = AuthSource.where(@auth_source_data)
			@domain2.reload
			expect(@domain2.auth_source_id).to eq auth_source.first.id
			expect(auth_source.count).to eq 1
		end

		it "edit domain, ldap failed: auth_source attributes is null" do
			attributes = [:name, :host, :port, :account, :account_password, :base_dn, :admin_account, :admin_password]
			attributes.each do |attribute|
				auth_source_data = @auth_source_data.clone
				auth_source_data[attribute] = nil
				check_update_failed(auth_source_data)
			end
		end

		it "eidt domain, ldap failed: ldap duplicated" do
			auth_source_data = @auth_source_data.clone
			auth_source_data.delete(:id)
			auth_source_data[:name] = "test_ldap"
			auth_source_data[:host] = '10.10.10.10'
			AuthSource.create(auth_source_data)
			
			auth_source = @auth_source_data.clone
			auth_source.delete(:id)
			auth_source[:name] = "test_ldap"
			check_update_failed(auth_source)
		end
	end
end