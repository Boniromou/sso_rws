class AddLockVersionToMaintenances < ActiveRecord::Migration
  def change
    add_column :maintenances, :lock_version, :integer
  end
end
