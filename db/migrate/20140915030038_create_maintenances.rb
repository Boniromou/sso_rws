class CreateMaintenances < ActiveRecord::Migration
  def up
    create_table :maintenances do |t|
      t.integer :property_id
      t.integer :maintenance_type_id
      t.datetime :start_time, :null => false
      t.datetime :end_time, :null => false
      t.integer :duration, :null => false
      t.boolean :allow_test_account, :null => false
      t.string :status, :null => false
      t.datetime :cancelled_at
      t.datetime :completed_at
      t.datetime :expired_at
      t.timestamps
    end
 
    execute "ALTER TABLE maintenances ADD CONSTRAINT fk_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
    execute "ALTER TABLE maintenances ADD CONSTRAINT fk_maintenance_type_id FOREIGN KEY (maintenance_type_id) REFERENCES maintenance_types(id);"
  end

  def down
    execute "ALTER TABLE maintenances DROP FOREIGN KEY fk_property_id;"
    execute "ALTER TABLE maintenances DROP FOREIGN KEY fk_maintenance_type_id;"
    drop_table :maintenances
  end
end
