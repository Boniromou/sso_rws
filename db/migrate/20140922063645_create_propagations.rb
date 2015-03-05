class CreatePropagations < ActiveRecord::Migration
  def up
    create_table :propagations do |t|
      t.integer :maintenance_id
      t.string :status, :null => false
      t.integer :retry, :null => false, :default => 0
      t.string :action, :null => false
      t.datetime :propagating_at
      t.datetime :propagated_at
      t.datetime :broken_at
      t.datetime :cancelled_at
      t.timestamps
    end

    execute "ALTER TABLE propagations ADD CONSTRAINT fk_maintenance_id FOREIGN KEY (maintenance_id) REFERENCES maintenances(id);"
  end

  def down
    execute "ALTER TABLE propagations DROP FOREIGN KEY fk_maintenance_id;"
    drop_table :propagations
  end
end
