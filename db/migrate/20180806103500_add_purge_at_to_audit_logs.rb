class AddPurgeAtToAuditLogs < ActiveRecord::Migration
  def change
    add_column :audit_logs, :purge_at, :datetime
    add_index :audit_logs, :purge_at
  end
end
