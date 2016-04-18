class AddTargetCasinoIdToSystemUserChangeLogs < ActiveRecord::Migration
  def up
  	add_column :system_user_change_logs, :target_casino_id, :integer, :null => false
  	remove_column :system_user_change_logs, :target_property_id
  	execute "TRUNCATE TABLE system_user_change_logs"
  end

  def down
  	add_column :system_user_change_logs, :target_property_id, :integer, :null => false
  	remove_column :system_user_change_logs, :target_casino_id
  end

end
