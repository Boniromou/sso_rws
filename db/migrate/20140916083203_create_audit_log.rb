class CreateAuditLog < ActiveRecord::Migration
  def up
    create_table :audit_logs do |t|
      t.string :audit_target, :null => false, :limit => 45
      t.string :action_type, :null => false, :limit => 45
      t.string :action, :null => false, :limit => 45
      t.string :action_status, :null => false, :limit => 45
      t.string :action_error, :limit => 255
      t.string :session_id, :limit => 255
      t.string :ip, :limit => 45
      t.string :action_by, :null => false, :limit => 45
      t.datetime :action_at, :null => false
      t.string :description, :limit => 255
      t.timestamps
    end
  end

  def down
    drop_table :audit_logs
  end
end
