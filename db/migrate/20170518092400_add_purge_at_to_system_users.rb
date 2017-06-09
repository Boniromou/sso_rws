class AddPurgeAtToSystemUsers < ActiveRecord::Migration
  def change
    add_column :system_users, :purge_at, :datetime, :null => true
    add_index :system_users, :purge_at
  end
end
