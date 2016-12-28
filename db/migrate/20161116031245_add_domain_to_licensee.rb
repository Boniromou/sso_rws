class AddDomainToLicensee < ActiveRecord::Migration
  def up
    add_column :licensees, :domain_id, :integer
    execute "ALTER TABLE licensees ADD CONSTRAINT fk_Licensees_DomainId FOREIGN KEY (domain_id) REFERENCES domains(id);"
    
    execute "ALTER TABLE licensees DROP FOREIGN KEY fk_Licensees_AuthSourceId;"
    remove_column :licensees, :auth_source_id
  end

  def down
    add_column :licensees, :auth_source_id, :integer
    execute "ALTER TABLE licensees ADD CONSTRAINT fk_Licensees_AuthSourceId FOREIGN KEY (auth_source_id) REFERENCES auth_sources(id);"
    
    execute "ALTER TABLE licensees DROP FOREIGN KEY fk_Licensees_DomainId;"
    remove_column :licensees, :domain_id
  end
end
