class AddDefaultValueToLockVersionToPropagations < ActiveRecord::Migration
  def change
    change_column_default :propagations, :lock_version, 0
  end
end
