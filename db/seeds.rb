# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


unless AuthSource.exists?(:id => 1, :name => "Laxino LDAP")
  AuthSource.create(:id => 1, :auth_type => "AuthSourceLdap", :name => "Laxino LDAP", :host => 'vmodc01.mo.laxino.com', :port => 389, :account => 'mo\svc.linux', :account_password => "Ccc1234%", :base_dn => "DC=mo,DC=laxino,DC=com", :attr_login => "sAMAccountName", :attr_firstname => "givenName", :attr_lastname => "sN", :attr_mail => "mail", :onthefly_register => 1, :domain => 'mo', :is_internal => true)
end

unless SystemUser.exists?(:username => 'portal.admin', :auth_source_id => 1)
  SystemUser.create!(:username => 'portal.admin', :status => true, :admin => true, :auth_source_id => 1)
end

unless Property.exists?(:id => 1000)
  Property.create(:id => 1000)
end

