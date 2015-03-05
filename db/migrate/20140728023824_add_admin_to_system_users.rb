class AddAdminToSystemUsers < ActiveRecord::Migration
  def change
    add_column :system_users, :admin, :boolean, :default => false, :null => false
  end
end
