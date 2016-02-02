class AddRoleTypeIdToRoles < ActiveRecord::Migration
  def up
    add_column :roles, :role_type_id, :integer
    execute "ALTER TABLE roles ADD CONSTRAINT fk_Roles_RoleTypeId FOREIGN KEY (role_type_id) REFERENCES role_types(id);"
  end

  def down
    execute "ALTER TABLE roles DROP FOREIGN KEY fk_Roles_RoleTypeId;"
    remove_column :roles, :role_type_id
  end
end
