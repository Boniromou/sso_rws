class AddTargetNameTargetDomainIndexToChangeLogs < ActiveRecord::Migration
  def change
    add_index :change_logs, [:target_username, :target_domain]
  end
end
