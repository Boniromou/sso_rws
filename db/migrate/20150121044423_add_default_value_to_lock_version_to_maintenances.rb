class AddDefaultValueToLockVersionToMaintenances < ActiveRecord::Migration
  def change
    change_column_default :maintenances, :lock_version, 0
  end
end
