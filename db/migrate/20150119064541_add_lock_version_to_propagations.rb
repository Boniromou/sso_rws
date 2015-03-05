class AddLockVersionToPropagations < ActiveRecord::Migration
  def change
    add_column :propagations, :lock_version, :integer
  end
end
