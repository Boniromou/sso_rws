class DropPropertiesSystemUsers < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE properties_system_users DROP FOREIGN KEY fk_PropertiesSystemUsers_PropertyId;"
    execute "ALTER TABLE properties_system_users DROP FOREIGN KEY fk_PropertiesSystemUsers_SystemUserId;"

    drop_table :properties_system_users
  end

  def down
  	create_table :properties_system_users do |t|
      t.integer :system_user_id, :null => false
      t.integer :property_id, :null => false
      t.boolean :status, :default => true, :null => false
      t.timestamps
    end

    execute "ALTER TABLE properties_system_users ADD CONSTRAINT fk_PropertiesSystemUsers_PropertyId FOREIGN KEY (property_id) REFERENCES properties(id);"
    execute "ALTER TABLE properties_system_users ADD CONSTRAINT fk_PropertiesSystemUsers_SystemUserId FOREIGN KEY (system_user_id) REFERENCES system_users(id);"
    add_index :properties_system_users, ["property_id", "system_user_id"], :unique => true
  end
end
