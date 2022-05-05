class AddStatusToSystemUsers < ActiveRecord::Migration
  def change
    add_column :system_users, :status, :boolean, :default => false, :null => false
  end
end
