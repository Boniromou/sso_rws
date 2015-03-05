class CreateRoleAssignments < ActiveRecord::Migration
  def change
    create_table :role_assignments do |t|
      t.string :user_type, :null => false, :limit => 60
      t.integer :user_id, :null => false
      t.integer :role_id, :null => false
      t.timestamps
    end
  end
end
