class AddPurgeAtToCasinosSystemUsers < ActiveRecord::Migration
  def change
    add_column :casinos_system_users, :purge_at, :datetime, :null => true
    add_index :casinos_system_users, :purge_at
  end
end
