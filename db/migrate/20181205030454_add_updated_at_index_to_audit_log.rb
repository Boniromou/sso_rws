class AddUpdatedAtIndexToAuditLog < ActiveRecord::Migration
  def change
    add_index :audit_logs, :updated_at, name: 'idx_updated_at'
  end
end
