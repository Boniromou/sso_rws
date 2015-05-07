class UpdateAuthSources < ActiveRecord::Migration
  def up
    AuthSource.find_by_name("Laxino LDAP").update_attributes(name: "Laxino LDAP MO")
    AuthSource.create!(:auth_type => "AuthSourceLdap", :name => "Laxino LDAP PH", :host => "10.81.223.27", :port => 389, :account => 'mo\svc.linux', :account_password => "Ccc1234%", :base_dn => "DC=mo,DC=laxino,DC=com", :attr_login => "sAMAccountName", :attr_firstname => "givenName", :attr_lastname => "sN", :attr_mail => "mail", :onthefly_register => 1, :domain => "mo")
  end

  def down
    AuthSource.find_by_name("Laxino LDAP MO").update_attributes(name: "Laxino LDAP")
    AuthSource.find_by_name("Laxino LDAP PH").delete
  end
end
