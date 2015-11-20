class CreateAuthSources < ActiveRecord::Migration
=begin
  class AuthSource < ActiveRecord::Base
    attr_accessible :auth_type, :name, :host, :port, :account, :account_password, :base_dn, :attr_login, :attr_firstname, :attr_lastname, :attr_mail, :onthefly_register 
  end
=end

  def change
    create_table :auth_sources do |t|
      t.string :auth_type, :limit => 30, :default => "", :null => false
      t.string :name, :limit => 60, :default => "", :null => false
      t.string :host, :limit => 60
      t.integer :port
      t.string :account, :limit => 60
      t.string :account_password, :limit => 60
      t.string :base_dn, :limit => 255
      t.string :attr_login, :limit => 30
      t.string :attr_firstname, :limit => 30
      t.string :attr_lastname, :limit => 60
      t.string :attr_mail, :limit => 30
      t.boolean :onthefly_register, :default => false, :null => false
    end

#     AuthSource.create!(:auth_type => "AuthSourceLdap", :name => "Laxino LDAP", :host => AUTH_SOURCE_HOST, :port => 389, :account => 'mo\svc.linux', :account_password => "Ccc1234%", :base_dn => "DC=mo,DC=laxino,DC=com", :attr_login => "sAMAccountName", :attr_firstname => "givenName", :attr_lastname => "sN", :attr_mail => "mail", :onthefly_register => 1)
  end
end
