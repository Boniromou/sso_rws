class CreateCasinos < ActiveRecord::Migration
  def up
  	create_table :casinos do |t|
      t.integer :licensee_id, :null => false
      t.string :name, :limit => 45, :null => false
      t.string :description, :limit => 255
      t.timestamps
    end

    add_index :casinos, ["name"], :unique => true

    execute "ALTER TABLE casinos ADD CONSTRAINT fk_Casinos_LicenseeId FOREIGN KEY (licensee_id) REFERENCES licensees(id);"
  end

  def down
  	execute "ALTER TABLE casinos DROP FOREIGN KEY fk_Casinos_LicenseeId;"
  	drop_table :casinos
  end
end
