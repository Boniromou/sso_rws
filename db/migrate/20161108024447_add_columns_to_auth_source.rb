class AddColumnsToAuthSource < ActiveRecord::Migration
  def up
    add_column(:auth_sources, :admin_account,  :string, limit: 60)
  	add_column(:auth_sources, :admin_password, :string, limit: 60)
  	remove_column :auth_sources, :is_internal
  end

  def down
    remove_column :auth_sources, :admin_account
  	remove_column :auth_sources, :admin_password
  	add_column :auth_sources, :is_internal, :boolean, :default => false, :null => false
  end
end
