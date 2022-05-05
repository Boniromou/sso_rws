class CreateProperties < ActiveRecord::Migration
  def up
    create_table :properties, :id => false do |t|
      t.integer :id
      t.timestamps
    end

    execute "ALTER TABLE properties ADD PRIMARY KEY (id);"
  end

  def down
    drop_table :properties
  end
end
