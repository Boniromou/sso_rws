class ChangeStatusTypeToSystemUsers < ActiveRecord::Migration
  def up
    change_column(:system_users, :status, :string, :limit => 45, :default => 'inactive', :null => false)
    execute "UPDATE system_users SET status = 'inactive' where status = '0'" 
    execute "UPDATE system_users SET status = 'active' where status = '1'"
  end

  def down
    change_column(:system_users, :status, :boolean, :default => false, :null => false)
  end
end
