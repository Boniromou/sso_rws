class CreateCasinosSystemUsers < ActiveRecord::Migration
  def up
  	create_table :casinos_system_users do |t|
      t.integer :system_user_id, :null => false
      t.integer :casino_id, :null => false
      t.boolean :status, :default => true, :null => false
      t.timestamps
    end

    execute "ALTER TABLE casinos_system_users ADD CONSTRAINT fk_CasinosSystemUsers_CasinoId FOREIGN KEY (casino_id) REFERENCES casinos(id);"
    execute "ALTER TABLE casinos_system_users ADD CONSTRAINT fk_CasinosSystemUsers_SystemUserId FOREIGN KEY (system_user_id) REFERENCES system_users(id);"
    add_index :casinos_system_users, ["casino_id", "system_user_id"], :unique => true
  end

  def down
  	execute "ALTER TABLE casinos_system_users DROP FOREIGN KEY fk_CasinosSystemUsers_CasinoId;"
    execute "ALTER TABLE casinos_system_users DROP FOREIGN KEY fk_CasinosSystemUsers_SystemUserId;"
    drop_table :casinos_system_users
  end
end
