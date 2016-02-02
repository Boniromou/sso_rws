class UpdateAuthSources < ActiveRecord::Migration
  def up
    remove_column :auth_sources, :attr_login
    remove_column :auth_sources, :attr_firstname
    remove_column :auth_sources, :attr_lastname
    remove_column :auth_sources, :attr_mail
    remove_column :auth_sources, :onthefly_register
    remove_column :auth_sources, :domain
    add_column :auth_sources, :encryption, :string
    add_column :auth_sources, :method, :string
    add_column :auth_sources, :search_scope, :string
  end

  def down
    add_column :auth_sources, :attr_login, :string
    add_column :auth_sources, :attr_firstname, :string
    add_column :auth_sources, :attr_lastname, :string
    add_column :auth_sources, :attr_mail, :string
    add_column :auth_sources, :onthefly_register, :boolean
    add_column :auth_sources, :domain, :string
    remove_column :auth_sources, :encryption
    remove_column :auth_sources, :method
    remove_column :auth_sources, :search_scope
  end
end
