class ChangeColumnsFromAuthSources < ActiveRecord::Migration
  def up
    remove_column :auth_sources, :auth_type
    remove_column :auth_sources, :name
    remove_column :auth_sources, :host
    remove_column :auth_sources, :port
    remove_column :auth_sources, :account
    remove_column :auth_sources, :account_password
    remove_column :auth_sources, :base_dn
    remove_column :auth_sources, :encryption
    remove_column :auth_sources, :method
    remove_column :auth_sources, :search_scope
    remove_column :auth_sources, :admin_account
    remove_column :auth_sources, :admin_password

    add_column :auth_sources, :token, :string, :null => false, :limit => 255
    add_column :auth_sources, :type, :string, :null => false
    add_column :auth_sources, :auth_source_detail_id, :integer
    execute "ALTER TABLE auth_sources ADD CONSTRAINT fk_AuthSources_AuthSourceDetailId FOREIGN KEY (auth_source_detail_id) REFERENCES auth_source_details(id);"
  end

  def down
    execute "ALTER TABLE auth_sources DROP FOREIGN KEY fk_AuthSources_AuthSourceDetailId;"
    remove_column :auth_sources, :token
    remove_column :auth_sources, :type
    remove_column :auth_sources, :auth_source_detail_id

    add_column :auth_sources, :auth_type, :string, :limit => 30, :default => "", :null => false
    add_column :auth_sources, :name, :string, :limit => 60, :default => "", :null => false
    add_column :auth_sources, :host, :string, :limit => 60
    add_column :auth_sources, :port, :integer
    add_column :auth_sources, :account, :string, :limit => 60
    add_column :auth_sources, :account_password, :string, :limit => 60
    add_column :auth_sources, :base_dn, :string, :limit => 255
    add_column :auth_sources, :encryption, :string, :limit => 255
    add_column :auth_sources, :method, :string, :limit => 255
    add_column :auth_sources, :search_scope, :string, :limit => 255
    add_column :auth_sources, :admin_account, :string, :limit => 60
    add_column :auth_sources, :admin_password, :string, :limit => 60
  end
end
