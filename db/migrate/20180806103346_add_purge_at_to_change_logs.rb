class AddPurgeAtToChangeLogs < ActiveRecord::Migration
  def change
    add_column :change_logs, :purge_at, :datetime
    add_index :change_logs, :purge_at
  end
end
