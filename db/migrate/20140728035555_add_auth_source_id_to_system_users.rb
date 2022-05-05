class AddAuthSourceIdToSystemUsers < ActiveRecord::Migration
  class AuthSource < ActiveRecord::Base;end

  class SystemUser < ActiveRecord::Base
    attr_accessible :username, :status, :admin, :auth_source_id 
  end

  def up
    add_column :system_users, :auth_source_id, :integer

    execute "ALTER TABLE system_users ADD FOREIGN KEY (auth_source_id) REFERENCES auth_sources(id);"

#    lax_ldap = AuthSource.find_by_name("Laxino LDAP")
#    SystemUser.create!(:username => 'portal.admin', :status => true, :admin => true, :auth_source_id => lax_ldap.id)
  end

  def down
    execute "ALTER TABLE system_users DROP FOREIGN KEY auth_source_id;"
    remove_column :system_users, :auth_source_id
  end
end
