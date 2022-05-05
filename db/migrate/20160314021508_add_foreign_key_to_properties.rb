class AddForeignKeyToProperties < ActiveRecord::Migration
  def up
    execute "ALTER TABLE properties ADD CONSTRAINT fk_Properties_CasinoId FOREIGN KEY (casino_id) REFERENCES casinos(id);"
  end

  def down
    execute "ALTER TABLE properties DROP FOREIGN KEY fk_Properties_CasinoId;"
  end
end
