class AddDomainIdToSystemUsers < ActiveRecord::Migration
  def up
    remove_index :system_users, ["username", "domain"]
    remove_column :system_users, :domain

    add_column :system_users, :domain_id, :integer
    execute "ALTER TABLE system_users ADD CONSTRAINT fk_SystemUsers_DomainId FOREIGN KEY (domain_id) REFERENCES domains(id);"

    add_index :system_users, ["username", "domain_id"], :unique => true
  end

  def down
    execute "ALTER TABLE system_users DROP FOREIGN KEY fk_SystemUsers_DomainId;"
    remove_index :system_users, ["username", "domain_id"]
    remove_column :system_users, :domain_id

    add_column :system_users, :domain, :string
    add_index :system_users, ["username", "domain"], :unique => true
  end
end
