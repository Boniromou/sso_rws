class RemoveAuthSourceIdFromDomains < ActiveRecord::Migration
  def up
    execute "ALTER TABLE domains DROP FOREIGN KEY fk_Domains_AuthSourceId;"
    remove_column :domains, :auth_source_id
  end

  def down
    add_column :domains, :auth_source_id, :integer
    execute "ALTER TABLE domains ADD CONSTRAINT fk_Domains_AuthSourceId FOREIGN KEY (auth_source_id) REFERENCES auth_sources(id);"
  end
end
