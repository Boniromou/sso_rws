# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

=begin
unless AuthSource.exists?(:id => 1, :name => "Laxino LDAP")
  AuthSource.create(:id => 1, :auth_type => "AuthSourceLdap", :name => "Laxino LDAP", :host => 'vmodc01.mo.laxino.com', :port => 389, :account => 'mo\svc.linux', :account_password => "Ccc1234%", :base_dn => "DC=mo,DC=laxino,DC=com", :attr_login => "sAMAccountName", :attr_firstname => "givenName", :attr_lastname => "sN", :attr_mail => "mail", :onthefly_register => 1, :domain => 'mo', :is_internal => true)
end
=end

=begin
unless SystemUser.exists?(:username => 'portal.admin', :auth_source_id => 1)
  SystemUser.create!(:username => 'portal.admin', :status => true, :admin => true, :auth_source_id => 1)
end
=end


Licensee.where(:id => 1000, :name => 'LAXINO', :timezone => 'Asia/Macao').first_or_create
Casino.where(:id => 1000, :name => 'LAXINO', :licensee_id => 1000).first_or_create
Property.where(:id => 1000, :name => 'LAXINO', :casino_id => 1000).first_or_create
RoleType.where(:name => 'internal').first_or_create
RoleType.where(:name => 'external').first_or_create
