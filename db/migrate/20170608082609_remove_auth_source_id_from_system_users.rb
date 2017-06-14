class RemoveAuthSourceIdFromSystemUsers < ActiveRecord::Migration
  def up
    execute "ALTER TABLE system_users DROP FOREIGN KEY system_users_ibfk_1;"
    remove_column :system_users, :auth_source_id
  end

  def down
    add_column :system_users, :auth_source_id, :integer
    execute "ALTER TABLE system_users ADD CONSTRAINT system_users_ibfk_1 FOREIGN KEY (auth_source_id) REFERENCES auth_sources(id);"
  end
end
