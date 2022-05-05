class AddVerifiedToSystemUser < ActiveRecord::Migration
  def change
    add_column :system_users, :verified, :boolean, :default => true, :null => false
  end
end
