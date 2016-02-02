class AddDomainToSystemUsers < ActiveRecord::Migration
  def up
    add_column :system_users, :domain, :string
    add_index :system_users, ["username", "domain"], :unique => true
  end

  def down
    remove_column :system_users, :domain
  end
end
