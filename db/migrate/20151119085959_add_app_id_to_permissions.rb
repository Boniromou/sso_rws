class AddAppIdToPermissions < ActiveRecord::Migration
  def up
    add_column :permissions, :app_id, :integer
    execute "ALTER TABLE permissions ADD CONSTRAINT fk_Permissions_AppId FOREIGN KEY (app_id) REFERENCES apps(id);"
  end

  def down
    execute "ALTER TABLE permissions DROP FOREIGN KEY fk_Permissions_AppId;"
    remove_column :permissions, :app_id
  end
end
