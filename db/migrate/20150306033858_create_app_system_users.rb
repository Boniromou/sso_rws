class CreateAppSystemUsers < ActiveRecord::Migration
  def up
    create_table :app_system_users do |t|
      t.integer :system_user_id, :null => false
      t.integer :app_id, :null => false
      t.timestamps
    end

    execute "ALTER TABLE app_system_users ADD FOREIGN KEY (system_user_id) REFERENCES system_users(id);"
    execute "ALTER TABLE app_system_users ADD FOREIGN KEY (app_id) REFERENCES apps(id);"
  end

  def down
    execute "ALTER TABLE app_system_users DROP FOREIGN KEY system_user_id;" 
    execute "ALTER TABLE app_system_users DROP FOREIGN KEY app_id;"
    drop_table :app_system_users
  end
end
