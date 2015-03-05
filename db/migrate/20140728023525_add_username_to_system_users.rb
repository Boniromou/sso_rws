class AddUsernameToSystemUsers < ActiveRecord::Migration
  def change
    add_column :system_users, :username, :string
  end
end
