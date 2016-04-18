class AddForeignKeyToDomainsCasinos < ActiveRecord::Migration
  def up
    execute "ALTER TABLE domains_casinos ADD CONSTRAINT fk_DomainsCasinos_DomainId FOREIGN KEY (domain_id) REFERENCES domains(id);"
    execute "ALTER TABLE domains_casinos ADD CONSTRAINT fk_DomainsCasinos_CasinoId FOREIGN KEY (casino_id) REFERENCES casinos(id);"
  end

  def down
    execute "ALTER TABLE domains_casinos DROP FOREIGN KEY fk_DomainsCasinos_DomainId;"
    execute "ALTER TABLE domains_casinos DROP FOREIGN KEY fk_DomainsCasinos_CasinoId;"
  end

end
