class AddCasinoIdToProperties < ActiveRecord::Migration
  def up
    add_column :properties, :casino_id, :integer
    execute "ALTER TABLE properties ADD CONSTRAINT fk_Properties_CasinoId FOREIGN KEY (casino_id) REFERENCES casinos(id);"
  end

  def down
    execute "ALTER TABLE properties DROP FOREIGN KEY fk_Properties_CasinoId;"
    remove_column :properties, :casino_id
  end
end
