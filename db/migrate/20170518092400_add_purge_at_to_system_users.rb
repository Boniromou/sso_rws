class AddPurgeAtToSystemUsers < ActiveRecord::Migration
  def change
    add_column :system_users, :purge_at, :datetime, :null => true
  end
end
