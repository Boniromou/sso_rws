class CreateRolePermissions < ActiveRecord::Migration
  def up
    create_table :role_permissions do |t|
      t.integer :role_id, :null => false
      t.integer :permission_id, :null => false
      t.timestamps
    end

    execute "ALTER TABLE role_permissions ADD FOREIGN KEY (role_id) REFERENCES roles(id);"
    execute "ALTER TABLE role_permissions ADD FOREIGN KEY (permission_id) REFERENCES permissions(id);"

  end

  def down
    execute "ALTER TABLE role_permissions DROP FOREIGN KEY role_id;"
    execute "ALTER TABLE role_permissions DROP FOREIGN KEY permission_id;"
    drop_table :role_permissions
  end
end
