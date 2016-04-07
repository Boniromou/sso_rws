class InitTargetCasinos < ActiveRecord::Migration
  def up
    execute "INSERT INTO target_casinos (change_log_id, target_casino_id) SELECT id, target_casino_id FROM change_logs;"
  end

  def down
    execute "UPDATE change_logs, target_casinos SET change_logs.target_casino_id = target_casinos.target_casino_id WHERE change_logs.id = target_casinos.change_log_id;"
  end
end