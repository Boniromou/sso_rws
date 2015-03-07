class AddAppIdToRoles < ActiveRecord::Migration
  def change
    add_column :roles, :app_id, :integer

    execute "ALTER TABLE roles ADD FOREIGN KEY (app_id) REFERENCES apps(id);" 
  end
end
