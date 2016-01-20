class CreateSystemUserChangeLogs < ActiveRecord::Migration
  def up
    create_table :system_user_change_logs do |t|
      t.string :change_detail, :limit => 1024, :default => '{}'
      t.string :target_username, :null => false
      t.integer :target_property_id, :null => false
      t.string :action, :null => false
      t.string :action_by, :limit => 1024, :default => '{}'
      t.string :description, :limit => 255
      t.timestamps
    end
  end

  def down
    drop_table :system_user_change_logs
  end
end
