class DropDomainsCasinos < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE domains_casinos DROP FOREIGN KEY fk_DomainsCasinos_CasinoId;"
    execute "ALTER TABLE domains_casinos DROP FOREIGN KEY fk_DomainsCasinos_DomainId;"
    remove_index :domains_casinos, ["domain_id", "casino_id"]
    drop_table :domains_casinos
  end

  def down
  	create_table :domains_casinos do |t|
      t.integer :domain_id, :null => false
      t.integer :casino_id, :null => false
      t.timestamps
    end
    add_index :domains_casinos, ["domain_id", "casino_id"], :unique => true
    execute "ALTER TABLE domains_casinos ADD CONSTRAINT fk_DomainsCasinos_DomainId FOREIGN KEY (domain_id) REFERENCES domains(id);"
    execute "ALTER TABLE domains_casinos ADD CONSTRAINT fk_DomainsCasinos_CasinoId FOREIGN KEY (casino_id) REFERENCES casinos(id);"
  end
end
