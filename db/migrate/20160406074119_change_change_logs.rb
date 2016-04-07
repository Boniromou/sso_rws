class ChangeChangeLogs < ActiveRecord::Migration
  Table_name = :change_logs

  def up
    change_column(Table_name, :target_username, :string, :limit => 255, :null => true)
    add_column(Table_name, :target_domain, :string, :limit => 45, :null => true)
    add_column(Table_name, :type, :string, :limit => 45, :null => true)
    remove_column(Table_name, :target_casino_id)

    execute "UPDATE change_logs SET type='SystemUserChangeLog' WHERE action='edit_role'"
  end

  def down
    remove_column(Table_name, :target_domain)
    remove_column(Table_name, :type)
    add_column(Table_name, :target_casino_id, :integer, :limit => 11, :null => true)
  end
end
