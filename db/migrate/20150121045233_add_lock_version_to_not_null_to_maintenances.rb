class AddLockVersionToNotNullToMaintenances < ActiveRecord::Migration
  def change
    change_column_null :maintenances, :lock_version, 0
  end
end
