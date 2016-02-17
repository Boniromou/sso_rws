class AddValueToRolePermissions < ActiveRecord::Migration
  def change
    add_column :role_permissions, :value, :string, :length => 255
  end
end
