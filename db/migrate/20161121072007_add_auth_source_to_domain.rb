class AddAuthSourceToDomain < ActiveRecord::Migration
  def up
    execute "ALTER TABLE domains DROP FOREIGN KEY fk_Domains_LicenseeId;"
    remove_index :domains, ["licensee_id"]
    remove_column :domains, :licensee_id

    add_column :domains, :auth_source_id, :integer
    add_index :domains, ["auth_source_id"], :unique => true
    execute "ALTER TABLE domains ADD CONSTRAINT fk_Domains_AuthSourceId FOREIGN KEY (auth_source_id) REFERENCES auth_sources(id);"
  end

  def down
  	execute "ALTER TABLE domains DROP FOREIGN KEY fk_Domains_AuthSourceId;"
    remove_index :domains, ["auth_source_id"]
    remove_column :domains, :auth_source_id
    
    add_column :domains, :licensee_id, :integer
    add_index :domains, ["licensee_id"], :unique => true
    execute "ALTER TABLE domains ADD CONSTRAINT fk_Domains_LicenseeId FOREIGN KEY (licensee_id) REFERENCES licensees(id);"
  end
end
