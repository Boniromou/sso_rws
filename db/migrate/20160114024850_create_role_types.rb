class CreateRoleTypes < ActiveRecord::Migration
  def up
    create_table :role_types do |t|
      t.string :name, :null => false
      t.string :description, :limit => 255
      t.timestamps
    end

     add_index :role_types, ["name"], :unique => true
  end

  def down
    drop_table :role_types
  end
end
