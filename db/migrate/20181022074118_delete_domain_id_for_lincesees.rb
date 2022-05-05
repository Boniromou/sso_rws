class DeleteDomainIdForLincesees < ActiveRecord::Migration
  def up
    execute "ALTER TABLE licensees DROP FOREIGN KEY fk_Licensees_DomainId;"
    remove_column :licensees, :domain_id
  end

  def down
    add_column :licensees, :domain_id, :integer
    execute "ALTER TABLE licensees ADD CONSTRAINT fk_Licensees_DomainId FOREIGN KEY (domain_id) REFERENCES domains(id);"
  end
end
