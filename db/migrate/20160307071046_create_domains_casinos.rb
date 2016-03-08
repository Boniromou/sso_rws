class CreateDomainsCasinos < ActiveRecord::Migration
  def up
  	create_table :domains_casinos do |t|
      t.integer :domain_id, :null => false
      t.integer :casino_id, :null => false
      t.timestamps
    end

    execute "ALTER TABLE domains_casinos ADD CONSTRAINT fk_DomainsCasinos_DomainId FOREIGN KEY (domain_id) REFERENCES domains(id);"
    execute "ALTER TABLE domains_casinos ADD CONSTRAINT fk_DomainsCasinos_CasinoId FOREIGN KEY (casino_id) REFERENCES casinos(id);"
    add_index :domains_casinos, ["domain_id", "casino_id"], :unique => true
  end

  def down
  	execute "ALTER TABLE domains_casinos DROP FOREIGN KEY fk_DomainsCasinos_DomainId;"
    execute "ALTER TABLE domains_casinos DROP FOREIGN KEY fk_DomainsCasinos_CasinoId;"
    drop_table :domains_casinos
  end
end
