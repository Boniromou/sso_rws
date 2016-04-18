class RenameSystemUserChangeLogs < ActiveRecord::Migration
  Old_name = 'system_user_change_logs'
  New_name = 'change_logs'

  def up
    rename_table(Old_name, New_name)
  end

  def down
    rename_table(New_name, Old_name)
  end
end
